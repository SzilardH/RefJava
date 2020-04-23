package hu.elte.refjava.api

import hu.elte.refjava.api.patterns.ASTBuilder
import hu.elte.refjava.api.patterns.PatternMatcher
import hu.elte.refjava.api.patterns.PatternParser
import hu.elte.refjava.api.patterns.Utils
import java.util.List
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.SimpleName
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jface.text.IDocument

class BlockRefactoring implements Refactoring {
	
	List<? extends ASTNode> target
	IDocument document
	
	val PatternMatcher matcher
	val ASTBuilder builder
	protected String matchingTypeReferenceString
	protected String replacementTypeReferenceString
	protected String targetTypeReferenceString
	protected String definitionTypeReferenceString
	List<ASTNode> replacement

	protected new(String matchingPatternString, String replacementPatternString) {
		nameBindings.clear
		typeBindings.clear
		parameterBindings.clear
		visibilityBindings.clear
		argumentBindings.clear
		setMetaVariables()
		matcher = new PatternMatcher(PatternParser.parse(matchingPatternString))
		builder = new ASTBuilder(PatternParser.parse(replacementPatternString))
	}
	
	override init(List<? extends ASTNode> target, IDocument document, List<TypeDeclaration> allTypeDeclInWorkspace) {
		this.target = target
		this.document = document
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
			if (!matcher.match(target, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, matchingTypeReferenceString)  ) {
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
		//Check.isInsideBlock(target)
		true
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
			val targetTypeDecl = Utils.getTypeDeclaration(target.head)
			val assignmentBeforeReplacement = Check.getAssignmentsInClass(targetTypeDecl)
			
			val rewrite = builder.rewrite
			target.tail.forEach[rewrite.remove(it, null)]
			
			val group = rewrite.createGroupNode(replacement)	
			rewrite.replace( target.head, group, null)
			val edits = rewrite.rewriteAST(document, null)
			edits.apply(document)
			
			
			val iCompUnit = Utils.getICompilationUnit(target.head)
			val compUnit = Utils.parseSourceCode(iCompUnit)
			val assignmentsAfterReplacement = Check.getAssignmentsInClass(compUnit.types.findFirst[
				(it as TypeDeclaration).resolveBinding.qualifiedName == targetTypeDecl.resolveBinding.qualifiedName] as TypeDeclaration)
			
			compUnit.recordModifications			
			val it1 = assignmentBeforeReplacement.iterator
			val it2 = assignmentsAfterReplacement.iterator
			
			while (it1.hasNext) {
				val value1 = it1.next
				val value2 = it2.next
				if(!(value1.leftHandSide as SimpleName).resolveBinding.isEqualTo((value2.leftHandSide as SimpleName).resolveBinding)) {
					val thisExpression = compUnit.AST.newThisExpression
					val fieldAccess = compUnit.AST.newFieldAccess
					fieldAccess.name.identifier = (value2.leftHandSide as SimpleName).identifier
					fieldAccess.expression = thisExpression
					value2.leftHandSide = fieldAccess
				}
			}
			Utils.applyChanges(compUnit, document)
			true
		} catch (Exception e) {
			println(e)
			false
		}
	}
}