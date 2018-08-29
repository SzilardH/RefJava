package hu.elte.refjava.api.patterns

import hu.elte.refjava.lang.refJava.PBlockExpression
import hu.elte.refjava.lang.refJava.PExpression
import hu.elte.refjava.lang.refJava.PMetaVariable
import hu.elte.refjava.lang.refJava.Pattern
import java.util.List
import java.util.Map
import org.eclipse.jdt.core.dom.AST
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.rewrite.ASTRewrite

class ASTBuilder {

	val Pattern pattern

	AST ast
	ASTRewrite rewrite
	Map<String, List<? extends ASTNode>> bindings

	new(Pattern pattern) {
		this.pattern = pattern
	}

	def getRewrite() {
		rewrite
	}

	def build(AST ast, Map<String, List<? extends ASTNode>> bindings) {
		this.ast = ast
		this.rewrite = ASTRewrite.create(ast)
		this.bindings = bindings

		return pattern.patterns.doBuildPatterns
	}

	def private dispatch doBuild(PMetaVariable metaVar) {
		val binding = bindings.get(metaVar.name)
		if (!binding.empty) {
			val copies = binding.map[ASTNode.copySubtree(ast, it)]
			rewrite.createGroupNode(copies)
		}
	}

	def private dispatch ASTNode doBuild(PBlockExpression blockPattern) {
		val block = ast.newBlock

		val builtStatements = blockPattern.expressions.doBuildPatterns
		block.statements.addAll(builtStatements)

		return block
	}

	def private doBuildPatterns(List<PExpression> patterns) {
		patterns.map[doBuild].filterNull.toList
	}

}
