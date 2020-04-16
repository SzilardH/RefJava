package hu.elte.refjava.api

import hu.elte.refjava.api.patterns.ASTBuilder
import hu.elte.refjava.api.patterns.PatternMatcher
import hu.elte.refjava.api.patterns.PatternParser
import hu.elte.refjava.api.patterns.Utils
import hu.elte.refjava.lang.refJava.PConstructorCall
import hu.elte.refjava.lang.refJava.PMemberFeatureCall
import hu.elte.refjava.lang.refJava.PMetaVariable
import java.util.List
import org.eclipse.jdt.core.ICompilationUnit
import org.eclipse.jdt.core.dom.AST
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.ASTParser
import org.eclipse.jdt.core.dom.CompilationUnit
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jface.text.Document
import org.eclipse.jface.text.IDocument

import static hu.elte.refjava.api.Check.*

class LambdaRefactoring implements Refactoring {
	
	List<? extends ASTNode> target
	List<TypeDeclaration> typeDeclList
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
		matcher = new PatternMatcher(PatternParser.parse(matchingPatternString))
		builder = new ASTBuilder(PatternParser.parse(replacementPatternString))
		val matchingPatternsFirstElement = PatternParser.parse(matchingPatternString).patterns.get(0)
		this.matchingString = matchingPatternString
		this.replacementString = replacementPatternString
		if (matchingPatternsFirstElement instanceof PMemberFeatureCall && (matchingPatternsFirstElement as PMemberFeatureCall).memberCallTarget instanceof PConstructorCall &&
			((matchingPatternsFirstElement as PMemberFeatureCall).memberCallTarget as PConstructorCall).anonInstance) {
			this.refactoringType = RefactoringType.MODIFICATION
		} else {
			this.interfaceToModify = null
			this.refactoringType = RefactoringType.NEW
		}
	}
	
	override init(List<? extends ASTNode> target, IDocument document, List<TypeDeclaration> allTypeDeclInWorkspace) {
		this.target = target
		this.document = document
		this.typeDeclList = allTypeDeclInWorkspace
		
		if(refactoringType == RefactoringType.MODIFICATION) {
			val matchingLambdaExpression = PatternParser.parse(matchingString).patterns.get(0) as PMemberFeatureCall
			val interfaceName = if((matchingLambdaExpression.memberCallTarget as PConstructorCall).metaName !== null) {
				nameBindings.get(((matchingLambdaExpression.memberCallTarget as PConstructorCall).metaName as PMetaVariable).name)
			} else {
				(matchingLambdaExpression.memberCallTarget as PConstructorCall).name
			}
			this.interfaceToModify = allTypeDeclInWorkspace.findFirst[it.name.identifier == interfaceName]
		}
	}
	
	def setTarget(List<?extends ASTNode> newTarget) {
		this.target = newTarget
	}
	
	override apply() {
		setMetaVariables()
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
			if (!matcher.match(target, nameBindings, typeBindings, parameterBindings, matchingTypeReferenceString)) {
				return false
			}
			target = matcher.modifiedTarget.toList
			bindings.putAll(matcher.bindings)
			
			return true 
		} catch (Exception e) {
			println(e)
			return false
		}
		
	}
	
	def protected void setMetaVariables() {
		//empty
	}
	
	def protected safeTargetCheck() {
		return true
	}
	
	def protected targetCheck(String targetPatternString) {
		try {
			if(!matcher.match(PatternParser.parse(targetPatternString), target, targetTypeReferenceString)) {
				return false
			}
			bindings.putAll(matcher.bindings)
			return true
		} catch (Exception e) {
			println(e)
			return false
		}
	}

	def private safeCheck() {
		try {
			return check()
		} catch (Exception e) {
			println(e)
			return false
		}
	}

	def protected check() {
		
		Check.allTypeDeclarationInWorkSpace = typeDeclList
		
		if(refactoringType == RefactoringType.NEW) {
			val replacementLambdaExpression = PatternParser.parse(replacementString).patterns.get(0) as PMemberFeatureCall
			var boolean isMetaName = false
			var String metaVarName
			var String interfaceName
			if((replacementLambdaExpression.memberCallTarget as PConstructorCall).metaName !== null) {
				isMetaName = true
				metaVarName = ((replacementLambdaExpression.memberCallTarget as PConstructorCall).metaName as PMetaVariable).name
			} else {
				interfaceName = (replacementLambdaExpression.memberCallTarget as PConstructorCall).name
			}	
			
			return if (isMetaName) { nameBindings.put(metaVarName, Check.generateNewName) true } else { Check.isFresh(interfaceName) } &&
				true
				//TODO	
			
		} else {
			return Check.references(interfaceToModify).size == 1 &&
				Check.contains(Check.references(interfaceToModify), target)
		}
	}

	def private safeBuild() {
		try {
			replacement = builder.build(target.head.AST, bindings, nameBindings, typeBindings, parameterBindings, replacementTypeReferenceString)
		} catch (Exception e) {
			println(e)
			return false
		}
		return true
	}

	def private safeReplace() {
		try {
			val rewrite = builder.rewrite
			target.tail.forEach[rewrite.remove(it, null)]
			
			val group = rewrite.createGroupNode(replacement)
			rewrite.replace( target.head, group, null)
			var edits = rewrite.rewriteAST(document, null)
			edits.apply(document)
			
			val compUnit = Utils.getCompilationUnit(target.head)
			val iCompUnit= compUnit.getJavaElement() as ICompilationUnit
			
			val parser = ASTParser.newParser(AST.JLS12)
			parser.resolveBindings = true
			parser.source = iCompUnit
			val newCompUnit = parser.createAST(null) as CompilationUnit
			
			newCompUnit.recordModifications
			val replacementLambdaExpression = PatternParser.parse(replacementString).patterns.get(0) as PMemberFeatureCall
			
			if(refactoringType == RefactoringType.NEW) {
				//if we are defining a new lambda expression, we just simply add a new interface to the target document
				val newInterface = builder.buildNewInterface(replacementLambdaExpression, newCompUnit.AST, bindings, nameBindings, typeBindings, parameterBindings, replacementTypeReferenceString)
				newCompUnit.types.add(newInterface)
			} else {
				//if we modifying an existing lambda expression, we have to find out where is the existing interface declaration on the workspace
				val interfaceCompUnit = Utils.getCompilationUnit(interfaceToModify)
				val interfaceICompUnit = interfaceCompUnit.getJavaElement() as ICompilationUnit
				if(interfaceICompUnit != iCompUnit) {
					//if the interface's document isn't the same as the target document, we are going to remove that interface from that document and then add the new
					interfaceCompUnit.recordModifications
					val newInterface = builder.buildNewInterface(replacementLambdaExpression, interfaceCompUnit.AST, bindings, nameBindings, typeBindings, parameterBindings, replacementTypeReferenceString)
					interfaceCompUnit.types.remove(interfaceToModify)
					interfaceCompUnit.types.add(newInterface)
					
					val interfaceDocument = new Document(interfaceICompUnit.source)
					val edits3 = interfaceCompUnit.rewrite(interfaceDocument, interfaceICompUnit.javaProject.getOptions(true))
					edits3.apply(interfaceDocument)
					val interfaceSource = interfaceDocument.get
					interfaceICompUnit.getBuffer.setContents(interfaceSource)	
				} else {
					//if the interface's document is the same as the target document, we just simply remove the interface from the target document and then add the new
					val newInterface = builder.buildNewInterface(replacementLambdaExpression, newCompUnit.AST, bindings, nameBindings, typeBindings, parameterBindings, replacementTypeReferenceString)
					val interfaceToRemove = newCompUnit.types.findFirst[(it as TypeDeclaration).resolveBinding.qualifiedName == interfaceToModify.resolveBinding.qualifiedName] as TypeDeclaration
					newCompUnit.types.remove(interfaceToRemove)
					newCompUnit.types.add(newInterface)
				}
			}
			
			val edits2 = newCompUnit.rewrite(document, iCompUnit.javaProject.getOptions(true))
			edits2.apply(document)
		   	val String newSource = document.get
			iCompUnit.getBuffer.setContents(newSource)
			
		} catch (Exception e) {
			println(e)
			return false
		}
		return true
	}
}