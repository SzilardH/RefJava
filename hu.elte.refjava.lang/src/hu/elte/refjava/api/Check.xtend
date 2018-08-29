package hu.elte.refjava.api

import java.util.List
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.ASTVisitor
import org.eclipse.jdt.core.dom.Block
import org.eclipse.jdt.core.dom.SimpleName
import org.eclipse.jdt.core.dom.Statement
import org.eclipse.jdt.core.dom.VariableDeclarationFragment
import org.eclipse.jdt.core.dom.VariableDeclarationStatement

class Check {

	def static isInsideBlock(ASTNode node) {
		node.parent instanceof Block
	}

	def static isInsideBlock(List<? extends ASTNode> nodes) {
		nodes.forall[isInsideBlock]
	}

	def static isVariableDeclaration(ASTNode node) {
		node instanceof VariableDeclarationStatement
	}

	def static asVariableDeclaration(ASTNode node) {
		if (node instanceof VariableDeclarationStatement) {
			node
		}
	}

	def static blockRemainder(ASTNode node) {
		val parent = node.parent
		if (parent instanceof Block) {
			(parent.statements as List<Statement>).dropWhile[it != node].toList
		}
	}

	def static isReferencedIn(VariableDeclarationStatement varDecl, List<? extends ASTNode> nodes) {
		(varDecl.fragments as List<VariableDeclarationFragment>).exists [
			val varBinding = resolveBinding
			nodes.exists [
				val visitor = new ASTVisitor() {
					public var found = false

					override visit(SimpleName name) {
						if (name.resolveBinding.isEqualTo(varBinding)) {
							found = true
							return false
						}

						return true
					}
				}

				accept(visitor)
				return visitor.found
			]
		]
	}

}
