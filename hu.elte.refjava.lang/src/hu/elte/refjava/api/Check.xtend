package hu.elte.refjava.api

import java.util.List
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.ASTVisitor
import org.eclipse.jdt.core.dom.Block
import org.eclipse.jdt.core.dom.SimpleName
import org.eclipse.jdt.core.dom.Statement
import org.eclipse.jdt.core.dom.VariableDeclarationFragment
import org.eclipse.jdt.core.dom.VariableDeclarationStatement
import java.lang.reflect.Type

class Check {

	
	def static getTypeOf(Type type) {
		return type
	}
	
	def static returnIntParameter() {
		val List<Pair<Type, String>> asd = newArrayList
		asd.add(new Pair<Type, String>(typeof(char), "x"))
		asd.add(new Pair<Type, String>(typeof(char), "y"))
		return asd
	}
	
	//actual
	def static isInsideBlock(ASTNode node) {
		node.parent instanceof Block
	}

	def static isInsideBlock(List<? extends ASTNode> nodes) {
		nodes.forall[isInsideBlock]
	}

	def dispatch static isVariableDeclaration(ASTNode node) {
		node instanceof VariableDeclarationStatement
	}
	
	def dispatch static isVariableDeclaration(List<?extends ASTNode> nodes) {
		for (node : nodes) {
			if( !(node instanceof VariableDeclarationStatement) ) {
				return false
			}
		}
		return true
	}

	def dispatch static asVariableDeclaration(ASTNode node) {
		if (node instanceof VariableDeclarationStatement) {
			node
		}
	}
	
	def dispatch static asVariableDeclaration(List<?extends ASTNode> nodes) {
		var Boolean l
		for (node : nodes) {
			if ( !(node instanceof VariableDeclarationStatement) ) {
				l = false
			}
		}
		
		if (l) {
			return nodes
		}
	}

	def static blockRemainder(ASTNode node) {
		val parent = node.parent
		if (parent instanceof Block) {
			(parent.statements as List<Statement>).dropWhile[it != node].toList
		}
	}

	def dispatch static isReferencedIn(VariableDeclarationStatement varDecl, List<? extends ASTNode> nodes) {
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
	
	def dispatch static boolean isReferencedIn(List<VariableDeclarationStatement> varDeclList, List<? extends ASTNode> nodes) {
		varDeclList.forall[!isReferencedIn(nodes)]
	}
	
	
	
	
}
