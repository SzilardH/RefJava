package hu.elte.refjava.api

import hu.elte.refjava.api.patterns.ASTBuilder
import hu.elte.refjava.api.patterns.PatternMatcher
import hu.elte.refjava.api.patterns.PatternParser
import java.lang.reflect.Type
import java.util.List
import java.util.Map
import org.eclipse.jdt.core.ICompilationUnit
import org.eclipse.jdt.core.dom.AST
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.ASTParser
import org.eclipse.jdt.core.dom.CompilationUnit
import org.eclipse.jdt.core.dom.MethodDeclaration
import org.eclipse.jdt.core.dom.SingleVariableDeclaration
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jface.text.IDocument
import hu.elte.refjava.api.patterns.Utils

class LambdaRefactoring implements Refactoring {
	
	List<? extends ASTNode> target
	IDocument document
	ICompilationUnit iCompUnit
	
	val PatternMatcher matcher
	val ASTBuilder builder
	protected String definitionString
	protected val Map<String, List<? extends ASTNode>> bindings = newHashMap
	protected val Map<String, String> nameBindings = newHashMap
	protected val Map<String, Type> typeBindings = newHashMap
	protected val Map<String, List<Pair<Type, String>>> parameterBindings = newHashMap
	protected String matchingTypeReferenceString
	protected String replacementTypeReferenceString
	protected String targetTypeReferenceString
	protected String definitionTypeReferenceString
	List<ASTNode> replacement

	protected new(String matchingPatternString, String replacementPatternString) {
		matcher = new PatternMatcher(PatternParser.parse(matchingPatternString))
		builder = new ASTBuilder(PatternParser.parse(replacementPatternString))
	}
	
	override init(List<? extends ASTNode> target, IDocument document, ICompilationUnit iCompUnit) {
		this.target = target
		this.document = document
		this.iCompUnit = iCompUnit
	}
	
	def setTarget(List<?extends ASTNode> newTarget) {
		this.target = newTarget
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
			setMetaVariables()
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
		return matcher.match(PatternParser.parse(targetPatternString), target, targetTypeReferenceString)
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
		//Check.isInsideBlock(target)
		return true
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
			
			val group = rewrite.createGroupNode( replacement )
			rewrite.replace( target.head, group, null)
			var edits = rewrite.rewriteAST(document, null)
			edits.apply(document)
			
			//testing
			val ASTParser parser = ASTParser.newParser(AST.JLS12);
			parser.setSource(iCompUnit);
			val CompilationUnit compUnit = parser.createAST(null) as CompilationUnit;

			if(!compUnit.types.exists[ (it as TypeDeclaration).name.identifier == builder.newInterface.name.identifier]) {
				
				compUnit.recordModifications
				
				val newInterface = compUnit.AST.newTypeDeclaration
				newInterface.interface = true
				newInterface.name.identifier = builder.newInterface.name.identifier
				for(method : builder.newInterface.bodyDeclarations) {
					val m = method as MethodDeclaration
					val newMethodDeclaration = compUnit.AST.newMethodDeclaration
					newMethodDeclaration.name.identifier = m.name.identifier
					newMethodDeclaration.returnType2 = Utils.getTypeFromId(m.returnType2.toString, compUnit.AST)
					newInterface.bodyDeclarations.add(newMethodDeclaration)
					for(arg : m.parameters ) {
						val a = arg as SingleVariableDeclaration
						val methodParameterDeclaration = compUnit.AST.newSingleVariableDeclaration
						methodParameterDeclaration.name.identifier = a.name.identifier
						methodParameterDeclaration.type = Utils.getTypeFromId(a.type.toString, compUnit.AST)
						newMethodDeclaration.parameters.add(methodParameterDeclaration)
					}
				}
				
				compUnit.types().add(newInterface)
				val edits2 = compUnit.rewrite(document, iCompUnit.javaProject.getOptions(true) )
				edits2.apply(document);
		   		val String newSource = document.get();		
				iCompUnit.getBuffer().setContents(newSource);
			}
		} catch (Exception e) {
			println(e)
			return false
		}
		return true
	}
}