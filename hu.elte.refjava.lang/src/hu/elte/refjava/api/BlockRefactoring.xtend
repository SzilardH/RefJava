package hu.elte.refjava.api

import hu.elte.refjava.api.patterns.ASTBuilder
import hu.elte.refjava.api.patterns.PatternMatcher
import hu.elte.refjava.api.patterns.PatternParser
import java.lang.reflect.Type
import java.util.List
import java.util.Map
import org.eclipse.jdt.core.ICompilationUnit
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jface.text.IDocument

class BlockRefactoring implements Refactoring {
	
	List<? extends ASTNode> target
	IDocument document
	
	val PatternMatcher matcher
	val ASTBuilder builder
	protected val Map<String, List<? extends ASTNode>> bindings = newHashMap
	protected val Map<String, String> nameBindings = newHashMap
	protected val Map<String, Type> typeBindings = newHashMap
	protected val Map<String, List<Pair<Type, String>>> parameterBindings = newHashMap
	protected String typeReferenceString
	List<ASTNode> replacement

	protected new(String matchingPatternString, String replacementPatternString) {
		matcher = new PatternMatcher(PatternParser.parse(matchingPatternString))
		builder = new ASTBuilder(PatternParser.parse(replacementPatternString))
	}
	
	override init(List<? extends ASTNode> target, IDocument document, ICompilationUnit iCompUnit) {
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
		setMetaVariables()
		if (!matcher.match(target, nameBindings, typeBindings, parameterBindings, typeReferenceString)  ) {
			return false
		}
		
		target = matcher.modifiedTarget.toList
		
		bindings.putAll(matcher.bindings)
		return true 
	}
	
	def protected void setMetaVariables() {
		//empty
	}
	
	def protected safeTargetCheck() {
		return true
	}
	
	def protected targetCheck(String targetPatternString) {
		
		return matcher.match(PatternParser.parse(targetPatternString), target)
	}

	def private safeCheck() {
		try {
			check()
		} catch (Exception e) {
			false
		}
	}

	def protected check() {
		Check.isInsideBlock(target)
	}

	def private safeBuild() {
		try {
			replacement = builder.build(target.head.AST, bindings, nameBindings, typeBindings, parameterBindings, typeReferenceString)
		} catch (Exception e) {
			System.out.println(e)
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
			val edits = rewrite.rewriteAST(document, null)
			edits.apply(document)
			
		} catch (Exception e) {
			return false
		}

		return true
	}
	
	
}