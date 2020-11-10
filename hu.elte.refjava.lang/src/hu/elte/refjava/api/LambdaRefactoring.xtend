package hu.elte.refjava.api

import hu.elte.refjava.api.patterns.ASTBuilder
import hu.elte.refjava.api.patterns.PatternMatcher
import hu.elte.refjava.api.patterns.PatternParser
import hu.elte.refjava.api.patterns.Utils
import hu.elte.refjava.lang.refJava.PConstructorCall
import hu.elte.refjava.lang.refJava.PMemberFeatureCall
import hu.elte.refjava.lang.refJava.PMetaVariable
import java.util.List
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.ExpressionStatement
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jface.text.Document
import org.eclipse.jface.text.IDocument

import static hu.elte.refjava.api.Check.*

class LambdaRefactoring implements Refactoring {
	
	List<? extends ASTNode> target
	List<TypeDeclaration> allTypeDecl
	IDocument document
	
	val PatternMatcher matcher
	val ASTBuilder builder
	val String matchingString
	val String replacementString
	val RefactoringType refactoringType
	protected TypeDeclaration interfaceToModify
	protected String definitionString
	protected String matchingTypeReferenceString
	protected String replacementTypeReferenceString
	protected String targetTypeReferenceString
	protected String definitionTypeReferenceString
	List<ASTNode> replacement
	
	enum RefactoringType {
		MODIFICATION,
		NEW
	}
	
	protected new(String matchingPatternString, String replacementPatternString) {
		nameBindings.clear
		typeBindings.clear
		parameterBindings.clear
		visibilityBindings.clear
		argumentBindings.clear
		setMetaVariables
		this.matcher = new PatternMatcher(PatternParser.parse(matchingPatternString))
		this.builder = new ASTBuilder(PatternParser.parse(replacementPatternString))
		this.matchingString = matchingPatternString
		this.replacementString = replacementPatternString

		val matchingPatterns = PatternParser.parse(matchingPatternString).patterns
		if (matchingPatterns.exists[Utils.isValidLambdaExpression(it)]) {
			this.refactoringType = RefactoringType.MODIFICATION
		} else {
			this.interfaceToModify = null
			this.refactoringType = RefactoringType.NEW
		}
	}
	
	override init(List<? extends ASTNode> target, IDocument document, List<TypeDeclaration> allTypeDeclInWorkspace) {
		this.target = target
		this.document = document
		this.allTypeDecl = allTypeDeclInWorkspace
		Check.allTypeDeclarationInWorkSpace = allTypeDeclInWorkspace
		
	}
	
	override apply() {
		return if(!safeTargetCheck) {
			Status.TARGET_MATCH_FAILED
		} else if (!safeMatch) {
			Status.MATCH_FAILED
		} else if (!safeCheck) {
			Status.CHECK_FAILED
		} else if (!safeBuild) {
			Status.BUILD_FAILED
		} else if (!safeReplace) {
			Status.REPLACEMENT_FAILED
		} else {
			Status.SUCCESS
		}
	}
	
	def private safeMatch() {
		try {
			if (!matcher.match(target, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, matchingTypeReferenceString)) {
				return false
			}
			target = matcher.modifiedTarget.toList
			bindings.putAll(matcher.bindings)
			true 
		} catch (Exception e) {
			println(e)
			false
		}
	}
	
	def protected void setMetaVariables() {
		//empty
	}
	
	def protected safeTargetCheck() {
		true
	}
	
	def protected targetCheck(String targetPatternString) {
		try {
			if(!matcher.match(PatternParser.parse(targetPatternString), target, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, targetTypeReferenceString)) {
				return false
			}
			bindings.putAll(matcher.bindings)
			true
		} catch (Exception e) {
			println(e)
			false
		}
	}

	def private safeCheck() {
		try {
			check()
		} catch (Exception e) {
			println(e)
			false
		}
	}

	def protected check() {
		
		if(refactoringType == RefactoringType.NEW) {
			val iCompUnit = Utils.getICompilationUnit(target.head)
			val compUnit = Utils.parseSourceCode(iCompUnit)
			
			val replacementPattern = PatternParser.parse(replacementString)
			val replacementLambdaExpression = replacementPattern.patterns.head
			if (((replacementLambdaExpression as PMemberFeatureCall).memberCallTarget as PConstructorCall).metaName !== null) {
				val metaVarName = (((replacementLambdaExpression as PMemberFeatureCall).memberCallTarget as PConstructorCall).metaName as PMetaVariable).name
				nameBindings.put(metaVarName, generateNewName)
			}
			
			val newLambdaExpression = builder.build(replacementPattern, compUnit.AST, bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, replacementTypeReferenceString).head as ExpressionStatement
			return isFresh(getLambdaName(newLambdaExpression))
				&& (lambdaVariableAssignments(getLambdaBody(newLambdaExpression)).forall[isDeclaredIn(it, getLambdaBody(newLambdaExpression))])
				
		} else {
			
			val matchingLambdaExpression = PatternParser.parse(matchingString).patterns.get(0) as PMemberFeatureCall
			val interfaceName = if((matchingLambdaExpression.memberCallTarget as PConstructorCall).metaName !== null) {
				nameBindings.get(((matchingLambdaExpression.memberCallTarget as PConstructorCall).metaName as PMetaVariable).name)
			} else {
				(matchingLambdaExpression.memberCallTarget as PConstructorCall).name
			}
			this.interfaceToModify = allTypeDecl.findFirst[it.name.identifier == interfaceName]
			
			return references(interfaceToModify).size == 1 &&
				contains(references(interfaceToModify), target)
		}
	}

	def private safeBuild() {
		try {
			replacement = builder.build(target.head.AST, bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, replacementTypeReferenceString)
			true
		} catch (Exception e) {
			println(e)
			false
		}		
	}

	def private safeReplace() {
		try {
			val rewrite = builder.rewrite
			target.tail.forEach[rewrite.remove(it, null)]
			val group = rewrite.createGroupNode(replacement)
			rewrite.replace(target.head, group, null)
			var edits = rewrite.rewriteAST(document, null)
			edits.apply(document)
			
			val iCompUnit= Utils.getICompilationUnit(target.head)
			val compUnit = Utils.parseSourceCode(iCompUnit)
			compUnit.recordModifications
			
			val replacementLambdaExpression = PatternParser.parse(replacementString).patterns.get(0) as PMemberFeatureCall
			if(refactoringType == RefactoringType.NEW) {
				//if we are defining a new lambda expression, we just simply add a new interface to the target document
				val newInterface = builder.buildNewInterface(replacementLambdaExpression, compUnit.AST, bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, replacementTypeReferenceString)
				compUnit.types.add(newInterface)
			} else {
				//if we modifying an existing lambda expression, we have to find out where is the existing interface declaration on the workspace
				val interfaceCompUnit = Utils.getCompilationUnit(interfaceToModify)
				val interfaceICompUnit = Utils.getICompilationUnit(interfaceCompUnit)
				if(interfaceICompUnit != iCompUnit) {
					//if the interface's document isn't the same as the target document, we are going to remove that interface from that document and then add the new
					interfaceCompUnit.recordModifications
					val newInterface = builder.buildNewInterface(replacementLambdaExpression, interfaceCompUnit.AST, bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, replacementTypeReferenceString)
					interfaceCompUnit.types.remove(interfaceToModify)
					interfaceCompUnit.types.add(newInterface)
					
					val interfaceDocument = new Document(interfaceICompUnit.source)
					Utils.applyChanges(interfaceCompUnit, interfaceDocument)
					interfaceICompUnit.getBuffer.setContents(interfaceDocument.get)	
				} else {
					//if the interface's document is the same as the target document, we just simply remove the interface from the target document and then add the new
					val newInterface = builder.buildNewInterface(replacementLambdaExpression, compUnit.AST, bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, replacementTypeReferenceString)
					val interfaceToRemove = compUnit.types.findFirst[(it as TypeDeclaration).resolveBinding.qualifiedName == interfaceToModify.resolveBinding.qualifiedName] as TypeDeclaration
					compUnit.types.remove(interfaceToRemove)
					compUnit.types.add(newInterface)
				}
			}
			Utils.applyChanges(compUnit, document)
			true
		} catch (Exception e) {
			println(e)
			return false
		}
	}
}