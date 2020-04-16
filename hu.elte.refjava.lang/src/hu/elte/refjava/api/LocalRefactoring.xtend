package hu.elte.refjava.api

import hu.elte.refjava.api.patterns.ASTBuilder
import hu.elte.refjava.api.patterns.PatternMatcher
import hu.elte.refjava.api.patterns.PatternParser
import java.util.List
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jface.text.IDocument

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

	protected new(String matchingPatternString, String replacementPatternString) {
		matcher = new PatternMatcher(PatternParser.parse(matchingPatternString))
		builder = new ASTBuilder(PatternParser.parse(replacementPatternString))
	}

	override init(List<? extends ASTNode> target, IDocument document, List<TypeDeclaration> allTypeDeclInWorkspace) {
		this.target = target
		this.document = document
	}

	override apply() {
		setMetaVariables()
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
		if (!matcher.match(target, nameBindings, typeBindings, parameterBindings, matchingTypeReferenceString)) {
			return false
		}

		bindings.putAll(matcher.bindings)
		return true
	}

	def private safeCheck() {
		try {
			check()
		} catch (Exception e) {
			false
		}
	}
	
	def protected void setMetaVariables() {
		//empty
	}

	def protected check() {
		Check.isInsideBlock(target)
	}

	def private safeBuild() {
		try {
			replacement = builder.build(target.head.AST, bindings, nameBindings, typeBindings, parameterBindings, replacementTypeReferenceString)
		} catch (Exception e) {
			return false
		}

		return true
	}

	def private safeReplace() {
		try {
			val rewrite = builder.rewrite
			target.tail.forEach[rewrite.remove(it, null)]

			val group = rewrite.createGroupNode(replacement)
			rewrite.replace(target.head, group, null)

			val edits = rewrite.rewriteAST(document, null)
			edits.apply(document)
		} catch (Exception e) {
			return false
		}

		return true
	}
}
