package hu.elte.refjava.api

import hu.elte.refjava.api.patterns.ASTBuilder
import hu.elte.refjava.api.patterns.PatternMatcher
import hu.elte.refjava.api.patterns.PatternParser
import java.util.List
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jface.text.IDocument

import static hu.elte.refjava.api.Check.*

class LocalRefactoring implements Refactoring {

	List<? extends ASTNode> target
	IDocument document

	val PatternMatcher matcher
	val ASTBuilder builder
	protected String matchingTypeReferenceString
	protected String replacementTypeReferenceString
	protected String targetTypeReferenceString
	protected String definitionTypeReferenceString
	List<ASTNode> replacement

	new(String matchingPatternString, String replacementPatternString) {
		nameBindings.clear
		typeBindings.clear
		parameterBindings.clear
		visibilityBindings.clear
		argumentBindings.clear
		setMetaVariables
		this.matcher = new PatternMatcher(PatternParser.parse(matchingPatternString))
		this.builder = new ASTBuilder(PatternParser.parse(replacementPatternString))
	}

	override init(List<? extends ASTNode> target, IDocument document, List<TypeDeclaration> allTypeDeclInWorkspace) {
		this.target = target
		this.document = document
	}

	override apply() {
		return if (!safeMatch) {
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
		if (!matcher.match(target, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, matchingTypeReferenceString)) {
			return false
		}
		bindings.putAll(matcher.bindings)
		true
	}

	def private safeCheck() {
		try {
			check()
		} catch (Exception e) {
			println(e)
			false
		}
	}
	
	def protected void setMetaVariables() {
		//empty
	}

	def protected check() {
		isInsideBlock(target)
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
			
			val group = if (replacement.size == 0) {
				null
			} else {
				rewrite.createGroupNode(replacement)
			}
			
			rewrite.replace(target.head, group, null)
			val edits = rewrite.rewriteAST(document, null)
			edits.apply(document)
			true
		} catch (Exception e) {
			println(e)
			false
		}
	}
}
