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
import org.eclipse.jdt.core.dom.FieldDeclaration
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jdt.core.dom.MethodDeclaration
import org.eclipse.jdt.core.dom.SingleVariableDeclaration
import hu.elte.refjava.api.patterns.Utils
import java.lang.reflect.Modifier

class Check {
	
	//for testing
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
	
	//class refact - field lifting
	def static enclosingClass(List<? extends ASTNode> target) {
		Utils.getTypeDeclaration(target.head)
	}
	
	def static superClass(TypeDeclaration typeDecl) {	
		
		
		
		val compUnit = Utils.getCompilationUnit(typeDecl)
		val superClassType = typeDecl.superclassType
		compUnit.types.findFirst[(it as TypeDeclaration).name.identifier == superClassType.toString] as TypeDeclaration
	}
	
	
	def static hasSuperClass(TypeDeclaration typeDecl) {
		return typeDecl.superclassType !== null
	}
	
	def static isPrivate(List<? extends ASTNode> target) {
		if (target.head instanceof FieldDeclaration) {
			return Modifier.isPrivate( (target.head as FieldDeclaration).getModifiers())
		} else if(target.head instanceof MethodDeclaration) {
			return Modifier.isPrivate( (target.head as MethodDeclaration).getModifiers())
		}
	}
	
	def static references(List<?extends ASTNode> target, TypeDeclaration typeDecl) {
		if (target.head instanceof FieldDeclaration) {
			val fieldDecl = target.head as FieldDeclaration
			val fragments = fieldDecl.fragments as List<VariableDeclarationFragment>
			val bodyDeclarations = typeDecl.bodyDeclarations
			val List<ASTNode> refs = newArrayList
			for(fragment : fragments) {
				val binding = fragment.resolveBinding
				for(declaration : bodyDeclarations) {
					
					val visitor = new ASTVisitor() {
						override visit(SimpleName name) {
							if (name.resolveBinding.equals(binding) && name != fragment.name) {
								println(name.parent)
								
								refs.add(name.parent)
							}
							return true
						}
					}
					(declaration as ASTNode).accept(visitor)
				}
			}
			refs
		} else if (target.head instanceof MethodDeclaration) {
			val methodDecl = target.head as MethodDeclaration
			val bodyDeclarations = typeDecl.bodyDeclarations
			val List<ASTNode> refs = newArrayList
			val binding = methodDecl.resolveBinding
			for(declaration : bodyDeclarations) {
				val visitor = new ASTVisitor() {
					override visit(SimpleName name) {
						if (name.resolveBinding.equals(binding) && name != methodDecl.name) {
							refs.add(name.parent)
						}
						return true
					}
				}
				(declaration as ASTNode).accept(visitor)
			}
			refs
		}
	}
	
	def static isUniqueFieldIn(List<? extends ASTNode> target, TypeDeclaration typeDecl) {
		val fieldDecl = target.head as FieldDeclaration
		
		!typeDecl.bodyDeclarations.exists[
			it instanceof FieldDeclaration && 
			((it as FieldDeclaration).fragments.head as VariableDeclarationFragment).name.identifier == (fieldDecl.fragments.head as VariableDeclarationFragment).name.identifier
		]
	}
	
	def static isUniqueMethodIn(List<? extends ASTNode> target, TypeDeclaration typeDecl) {
		val methodDecl = target.head as MethodDeclaration
		
		val methodsWithSameNameAndAmountOfParameter = typeDecl.bodyDeclarations.filter[
			it instanceof MethodDeclaration && (it as MethodDeclaration).name.identifier == methodDecl.name.identifier
			&& (it as MethodDeclaration).parameters.size == methodDecl.parameters.size
		]
		if(methodsWithSameNameAndAmountOfParameter.size > 0) {
			if(methodDecl.parameters.size == 0) {
				false
			} else {
				for(var int i = 0; i < methodsWithSameNameAndAmountOfParameter.size; i++) {
					for (var int j = 0; i < methodDecl.parameters.size; i++) {
						val methodParameter = (methodsWithSameNameAndAmountOfParameter.get(i) as MethodDeclaration).parameters.get(j) as SingleVariableDeclaration
						if ( (methodDecl.parameters.get(j) as SingleVariableDeclaration).type.toString != methodParameter.type.toString) {
							return true
						}
					}
				}
				false
			}
		} else {
			true
		}
	}
	
	def static accessedFieldsOfEnclosingClass(List<? extends ASTNode> target, TypeDeclaration typeDecl) {
		val methodDecl = target.head as MethodDeclaration
		
		val List<ASTNode> accessedFields = newArrayList 
		val methodBody = methodDecl.body
		val classFields = typeDecl.bodyDeclarations.filter[it instanceof FieldDeclaration]
		for (field : classFields) {
			val fragments = (field as FieldDeclaration).fragments as List<VariableDeclarationFragment>
			for(fragment : fragments) {
				val binding = fragment.resolveBinding
				methodBody.statements.exists[
					val visitor = new ASTVisitor() {
						public var found = false
						
						override visit(SimpleName name) {
							if(name.resolveBinding.equals(binding)) {
								found = true
								return false
							}
							return true
						}
					}
					(it as ASTNode).accept(visitor)
					if(visitor.found) {
						accessedFields.add(field as ASTNode)
					}
					return visitor.found
				]
			}
		}
		accessedFields
	}
	
	def static accessedMethodsOfEnclosingClass(List<? extends ASTNode> target, TypeDeclaration typeDecl) {
		val methodDecl = target.head as MethodDeclaration
		
		val List<ASTNode> accessedMethods = newArrayList
		val methodBody = methodDecl.body
		val classMethods = typeDecl.bodyDeclarations.filter[it instanceof MethodDeclaration]
		for (method : classMethods) {
			val binding = (method as MethodDeclaration).resolveBinding
			methodBody.statements.exists[
				val visitor = new ASTVisitor() {
					public var found = false
					
					override visit(SimpleName name) {
						if(name.resolveBinding.equals(binding) && name != methodDecl.name) {
							found = true
							return false
						}
						return true
					}
				}
				(it as ASTNode).accept(visitor)
				if(visitor.found) {
					accessedMethods.add(method as ASTNode)
				}
				return visitor.found			
			]
		}
		accessedMethods
	}
	
	
	
	
}
