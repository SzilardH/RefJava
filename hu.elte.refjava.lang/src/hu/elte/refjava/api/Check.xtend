package hu.elte.refjava.api

import hu.elte.refjava.api.patterns.Utils
import hu.elte.refjava.lang.refJava.Visibility
import java.lang.reflect.Modifier
import java.util.List
import java.util.Queue
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.ASTVisitor
import org.eclipse.jdt.core.dom.AnonymousClassDeclaration
import org.eclipse.jdt.core.dom.ArrayType
import org.eclipse.jdt.core.dom.Assignment
import org.eclipse.jdt.core.dom.Block
import org.eclipse.jdt.core.dom.ClassInstanceCreation
import org.eclipse.jdt.core.dom.ExpressionStatement
import org.eclipse.jdt.core.dom.FieldDeclaration
import org.eclipse.jdt.core.dom.ITypeBinding
import org.eclipse.jdt.core.dom.MethodDeclaration
import org.eclipse.jdt.core.dom.MethodInvocation
import org.eclipse.jdt.core.dom.Name
import org.eclipse.jdt.core.dom.QualifiedName
import org.eclipse.jdt.core.dom.ReturnStatement
import org.eclipse.jdt.core.dom.SimpleName
import org.eclipse.jdt.core.dom.SingleVariableDeclaration
import org.eclipse.jdt.core.dom.Statement
import org.eclipse.jdt.core.dom.Type
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jdt.core.dom.VariableDeclarationFragment
import org.eclipse.jdt.core.dom.VariableDeclarationStatement

class Check {

	protected static List<TypeDeclaration> allTypeDeclarationInWorkSpace
	
	/////////////////
	//public checks//
	/////////////////
	
	/**
	 * Determines whether the given list of ASTNodes consist of one element.
	 * @param target		the list of ASTNodes
	 * @return				true, if target consist of on element, false otherwise
	 */
	def static isSingle(List<? extends ASTNode> target) {
		target.size == 1
	}
	
	/**
	 * Determines whether the given ASTNode is located inside a Block.
	 * @param node			the ASTnode
	 * @return				true, if node located inside a Block, false otherwise
	 */
	def static isInsideBlock(ASTNode node) {
		node.parent instanceof Block
	}
	
	/**
	 * Determines whether the all of the given list of ASTNodes' element is located in a Block.
	 * @param nodes			the list of ASTNodes
	 * @return				true, if all of node's element located inside a Block, false otherwise
	 */
	def static isInsideBlock(List<? extends ASTNode> nodes) {
		nodes.forall[isInsideBlock]
	}

	/**
	 * Determines whether the given ASTNode is a variable declaration.
	 * @param node			the list of ASTNodes
	 * @return				true, if node is a variable declaration, false otherwise
	 */
	def dispatch static isVariableDeclaration(ASTNode node) {
		node instanceof VariableDeclarationStatement
	}
	
	/**
	 * Determines whether the all of the given list of ASTNodes' element is a variable declaration.
	 * @param node			the list of ASTNodes
	 * @return				true, if all of nodes' element is a variable declaration, false otherwise
	 */
	def dispatch static isVariableDeclaration(List<?extends ASTNode> nodes) {
		nodes.forall[it instanceof VariableDeclarationStatement]
	}

	def dispatch static asVariableDeclaration(ASTNode node) {
		if (node instanceof VariableDeclarationStatement) {
			node
		}
	}

	def dispatch static asVariableDeclaration(List<?extends ASTNode> nodes) {
		if (nodes.isVariableDeclaration) {
			nodes as List<VariableDeclarationStatement>
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
		varDeclList.exists[it.isReferencedIn(nodes)]
	}
	
	
	//OPTIONAL CHECK
	//determines whether the selected nodes contains a ReturnExpression with an expression that is not null
	def static containsValueReturn(List<? extends ASTNode> target) {
		target.exists [
			val visitor = new ASTVisitor() {
				public var found = false
				override visit(ReturnStatement statement) {
					if (statement.expression !== null) {
						found = true
						return false
					}
					true
				}
			}
			it.accept(visitor)
			visitor.found
		]
	}
	
		
	//OPTIONAL CHECK
	//determines whether the selected nodes contains a ReturnExpression with an expression that is null
	def static containsVoidReturn(List<? extends ASTNode> target) {
		target.exists [
			val visitor = new ASTVisitor() {
				public var found = false
				override visit(ReturnStatement statement) {
					if (statement.expression === null) {
						found = true
						return false
					}
					true
				}
			}
			it.accept(visitor)
			visitor.found
		]
	}
	
	//OPTIONAL CHECK
	//gets the first ReturnExpression which expression is null from the selected nodes.. returns null if such a node doesn't exists
	def static getVoidReturn(List<? extends ASTNode> target) {
		val List<ASTNode> result = newArrayList
		target.exists [
			val visitor = new ASTVisitor() {
				public var found = false
				override visit(ReturnStatement statement) {
					if (statement.expression === null) {
						found = true
						result.add(statement)
						return false
					}
					true
				}
			}
			it.accept(visitor)
			visitor.found
		]
		result.head as ReturnStatement
	}
	
	/**
	 * Determines whether if the a ReturnStatement is the last possible execution node of the Block which has the statement.
	 * @param statement		the ReturnStatement
	 * @return				true, if its the last execution path, false otherwise
	 */
	def static isLastExecutionNode(ReturnStatement statement) {
		var firstLevelNodeInMethod = statement as ASTNode
		while (!((firstLevelNodeInMethod.parent instanceof Block) && ((firstLevelNodeInMethod.parent as Block).parent instanceof MethodDeclaration))) {
			firstLevelNodeInMethod = firstLevelNodeInMethod.parent
		}
		val node = firstLevelNodeInMethod
		val nodesAfterReturnStatement = (firstLevelNodeInMethod.parent as Block).statements.dropWhile[it != node]
		nodesAfterReturnStatement.size == 1 && 	nodesAfterReturnStatement.head == node
	}
	
	/**
	 * Gets the identifier of the first element of the given list of ASTNodes.
	 * Note: Only works if the first element of the given list is a MethodDeclaration. Returns null otherwise.
	 * @param target			the list of ASTNodes
	 * @return					the identifier of target's first element
	 */
	def static String getMethodName(List<? extends ASTNode> target) {
		if (target.head instanceof MethodDeclaration) {
			return (target.head as MethodDeclaration).name.identifier
		}
		null
	}
	
	/**
	 * Gets the identifiers of the first element of the given list of ASTNodes.
	 * Note: Only works if the first element of the given list is a FieldDeclaration. Returns null otherwise.
	 * @param target			the list of ASTNodes
	 * @return					the list of identifiers of target's first element
	 */
	def static getFragmentNames(List<? extends ASTNode> target) {
		if(target.head instanceof FieldDeclaration) {
			val fragments = (target.head as FieldDeclaration).fragments as List<VariableDeclarationFragment>
			var List<String> fragmentNames = newArrayList
			for(fragment : fragments) {
				fragmentNames.add(fragment.name.identifier)
			}
			return fragmentNames
		}
		null
	}
	
	/**
	 * Gets the type of a list of ASTNodes' first element.
	 * Note: Only works if the first element of the given list is either a FieldDeclaration, or a MethodDeclaration. Returns null otherwise.
	 * @param target		the list of ASTNodes
	 * @return				the type or return type of target's first element (org.eclipse.jdt.core.dom.Type)
	 */
	def dispatch static Type type(List<? extends ASTNode> target) {
		if (target.head instanceof MethodDeclaration) {
			return type(target.head)
		} else if (target.head instanceof FieldDeclaration) {
			return type(target.head)
		}
		null
	}
	
	/**
	 * Gets the visibility of a list of ASTNodes' first element.
	 * Note: Only works if the first element of the given list is either a FieldDeclaration, or a MethodDeclaration. Returns null otherwise.
	 * @param target		the list of ASTNodes
	 * @return				the visibility of target's first element (hu.elte.refjava.lang.refJava.Visibility)
	 */
	def dispatch static Visibility visibility(List<? extends ASTNode> target) {
		if(target.head instanceof MethodDeclaration) {
			return visibility(target.head as MethodDeclaration)
		} else if (target.head instanceof FieldDeclaration) {
			return visibility(target.head as FieldDeclaration)
		}
		null
	}
	
	/**
	 * Gets the parameters of a list of ASTNodes' first element.
	 * Note: Only works if the first element of the given list is a MethodDeclaration. Returns null otherwise.
	 * @param target		the list of ASTNodes
	 * @return				the parameters of target's first element (list of org.eclipse.jdt.core.dom.SingleVariableDeclaration)
	 */
	def dispatch static parameters(List<? extends ASTNode> target) {
		if(target.head instanceof MethodDeclaration) {
			return (target.head as MethodDeclaration).parameters as List<SingleVariableDeclaration>
		}
		null
	}
	
	/**
	 * Gets the class of a list of ASTNode's first element.
	 * Note: The the returned class will be on the same AST as the given list of ASTNodes' first element.
	 * @param target		the list of ASTNodes
	 * @return				the class of target's first element (org.eclipse.jdt.core.dom.TypeDeclaration)
	 */
	def static enclosingClass(List<? extends ASTNode> target) {
		Utils.getTypeDeclaration(target.head)
	}
	
	/**
	 * Generates a fresh TypeDeclaration identifier in the workspace.
	 * @return			the newly generated identifier
	 */
	def static generateNewName() {
		var int i = 1
		var newName = "newLambda"
		while(!isFresh(newName)) {
			newName = "newLambda" + i++
		}
		newName
	}
	
	/**
	 * Determines if an identifier is used in the workspace as a TypeDeclaration identifier.
	 * @param name		the identifier
	 * @return			true, if identifier isn't used, false otherwise
	 */
	def static isFresh(String name) {
		!allTypeDeclarationInWorkSpace.exists[it.name.identifier == name]
	}
	
	/**
	 * Gets all references to a MethodDeclartion that can get accessed via public interface.
	 * @param methodName				the MethodDeclaration's name
	 * @param methodParameters			the MethodDeclaration's parameters
	 * @param targetTypeDeclaration		the MethodDeclaration's TypeDeclaration
	 * @return							list of ASTNodes
	 */
	def protected static publicReferences(String methodName, List<SingleVariableDeclaration> methodParameters, TypeDeclaration targetTypeDeclaration) {
		references("public", methodName, methodParameters, targetTypeDeclaration)
	}
	
	/**
	 * Gets all references to a FieldDeclaration that can get accessed via public interface.
	 * @param fragmentNames				the FieldDeclaration's fragment names
	 * @param targetTypeDeclaration		the FieldDeclaration's TypeDeclaration
	 * @return							list of ASTNodes
	 */
	def protected static publicReferences(List<String> fragmentNames, TypeDeclaration targetTypeDecl) {
		references("public", fragmentNames, targetTypeDecl)
	}
	
	////////////////////////////
	//private/protected checks//
	////////////////////////////
	
	/**
	 * Gets all Assignments from a TypeDeclareation.
	 * @param typeDecl		the target TypeDeclaration
	 * @return				all Assignments in the target TypeDeclaration
	 */
	def protected static getAssignmentsInClass(TypeDeclaration typeDecl) {
		val List<Assignment> assignments = newArrayList
		val visitor = new ASTVisitor() {
			override visit(Assignment assignment) {
				if (assignment.leftHandSide instanceof SimpleName) {
					assignments.add(assignment)
				}
				return true
			}
		}
		typeDecl.accept(visitor)
		assignments
	}	
	
	//gets all references to a TypeDeclaration in the workspace, except the TypeDeclaration itself
	//TODO
	def protected static references(TypeDeclaration typeDecl) {
		val List<ASTNode> references = newArrayList
		val binding = typeDecl.name.resolveBinding
		allTypeDeclarationInWorkSpace.forEach[
			val visitor = new ASTVisitor() {
				override visit(SimpleName name) {
					if (name.resolveBinding.isEqualTo(binding) && name != typeDecl.name) {
						references.add(name)
					}
					true
				}
			}
			it.accept(visitor)
		]
		references
	}
	
	/**
	 * //TODO
	 * @param references	
	 * @param target		
	 * @return				
	 */
	def protected static contains(List<ASTNode> references, List<? extends ASTNode> target) {
		if(target.head instanceof ExpressionStatement &&
			(target.head as ExpressionStatement).expression instanceof MethodInvocation &&
			((target.head as ExpressionStatement).expression as MethodInvocation).expression instanceof ClassInstanceCreation &&
			(((target.head as ExpressionStatement).expression as MethodInvocation).expression as ClassInstanceCreation).anonymousClassDeclaration !== null ) {
			
			for(refs : references) {
				if( (refs as SimpleName).resolveBinding.isEqualTo( (((target.head as ExpressionStatement).expression as MethodInvocation).expression as ClassInstanceCreation).type.resolveBinding) ) {
					return true
				}
			}
		}
		false
	}
	
	/**
	 * Gets the type identifier of a ClassInstanceCreation (lambda expression's expression).
	 * @param exprStatement		the lambda expression (as an ExpressionStatement, which has a MethodInvocation expression)
	 * @return					the lambda expression's identifier
	 */
	def protected static getLambdaName(ExpressionStatement exprStatement) {
		((exprStatement.expression as MethodInvocation).expression as ClassInstanceCreation).type.toString
	}
	
	/**
	 * Gets a ClassInstanceCreation's anonymous class declaration.
	 * @param exprStatement		the lambda expression (as an ExpressionStatement, which has a MethodInvocation expression)
	 * @return					the lambda expression's body
	 */
	def protected static getLambdaBody(ExpressionStatement exprStatement) {
		((exprStatement.expression as MethodInvocation).expression as ClassInstanceCreation).anonymousClassDeclaration
	}
	
	/**
	 * Gets all Assignments from an anonymous class declaration.
	 * @param anonClass		the AnonymousClassDeclaration
	 * @return				all Assignments from the given AnonymousClassDeclaration
	 */
	def protected static lambdaVariableAssignments(AnonymousClassDeclaration anonClass) {
		val List<Assignment> variableWrites = newArrayList
		anonClass.bodyDeclarations.forEach [
			val visitor = new ASTVisitor() {
				override visit(Assignment assignment) {
					variableWrites.add(assignment)
				}
			}
			(it as ASTNode).accept(visitor)
		]
		variableWrites
	}
	
	/**
	 * Determines whether an Assignment's left hand side is declared in the given AnonymousClassDeclaration
	 * @param assignment		the Assignment
	 * @param anonClass			the AnonymousClassDeclaration
	 * @return					true, if assignment's left hand side declared in anonClass
	 */
	def protected static isDeclaredIn(Assignment assignment, AnonymousClassDeclaration anonClass) {
		if(assignment.leftHandSide instanceof SimpleName) {
			val varName = (assignment.leftHandSide as SimpleName)
			val List<ASTNode> namesList = newArrayList
			anonClass.bodyDeclarations.forEach[
				val visitor = new ASTVisitor() {
					override visit(SimpleName name) {
						if(name.identifier == varName.identifier) {
							namesList.add(name)
							return true
						}
						true
					}
				}
				(it as ASTNode).accept(visitor)
			]
			for (name : namesList) {
				if (name == varName) {
					return false
				} else if (name.parent instanceof VariableDeclarationFragment) {
					return true
				}
			}
			return false
		}
		true
	}
	
	/**
	 * Gets the return type of a MethodDeclaration.
	 * @param methodDecl		the MethodDeclaration
	 * @return					the return type of the given MethodDeclaration (org.eclipse.jdt.core.dom.Type)
	 */
	def protected dispatch static type(MethodDeclaration methodDecl) {
		methodDecl.returnType2
	}
	
	/**
	 * Gets the type of a FieldDeclaration.
	 * @param fieldDecl			the FieldDeclaration
	 * @return					the type of the given FieldDeclaration (org.eclipse.jdt.core.dom.Type)
	 */
	def protected dispatch static type(FieldDeclaration fieldDecl) {
		fieldDecl.type
	}
	
	/**
	 * Gets the visibility of a FieldDeclaration.
	 * @param fieldDecl		the FieldDeclaration
	 * @return				the visibility of the given FieldDeclaration (hu.elte.refjava.lang.refJava.Visibility)
	 */
	def protected dispatch static visibility(FieldDeclaration fieldDecl) {
		val modifiers = fieldDecl.getModifiers
		switch modifiers {
			case modifiers.bitwiseAnd(Modifier.PUBLIC) > 0 : Visibility.PUBLIC
			case modifiers.bitwiseAnd(Modifier.PRIVATE) > 0 : Visibility.PRIVATE
			case modifiers.bitwiseAnd(Modifier.PROTECTED) > 0 : Visibility.PROTECTED
			case modifiers.bitwiseAnd(Modifier.PROTECTED) == 0 && modifiers.bitwiseAnd(Modifier.PRIVATE) == 0 && modifiers.bitwiseAnd(Modifier.PUBLIC) == 0 : Visibility.PACKAGE
		}
	}
	
	/**
	 * Gets the visibility of a MethodDeclaration.
	 * @param methodDecl		the MethodDeclaration
	 * @return					the visibility of the given MethodDeclaration (hu.elte.refjava.lang.refJava.Visibility)
	 */
	def protected dispatch static visibility(MethodDeclaration methodDecl) {
		val modifiers = methodDecl.getModifiers
		switch modifiers {
			case modifiers.bitwiseAnd(Modifier.PUBLIC) > 0 : Visibility.PUBLIC
			case modifiers.bitwiseAnd(Modifier.PRIVATE) > 0 : Visibility.PRIVATE
			case modifiers.bitwiseAnd(Modifier.PROTECTED) > 0 : Visibility.PROTECTED
			case modifiers.bitwiseAnd(Modifier.PROTECTED) == 0 && modifiers.bitwiseAnd(Modifier.PRIVATE) == 0 && modifiers.bitwiseAnd(Modifier.PUBLIC) == 0 : Visibility.PACKAGE
		}
	}
	
	/**
	 * Gets the parameters of a MethodDeclaration.
	 * @param methodDecl		the MethodDeclaration
	 * @return					the parameters of the given MethodDeclaration (list of org.eclipse.jdt.core.dom.SingleVariableDeclaration)
	 */
	def protected dispatch static parameters(MethodDeclaration methodDecl) {
		methodDecl.parameters as List<SingleVariableDeclaration>
	}
	
	/**
	 * Gets the superclass of a TypeDeclaration.
	 * Note: Only works if the given TypeDeclaration has a superclass. Also, the returned superclass will be on an another AST.
	 * @param typeDecl		the TypeDeclaration
	 * @return				typeDecl's superclass (org.eclipse.jdt.core.dom.TypeDeclaration)
	 */
	def protected static superClass(TypeDeclaration typeDecl) {
		allTypeDeclarationInWorkSpace.findFirst[it.resolveBinding.qualifiedName == typeDecl.superclassType.resolveBinding.qualifiedName]
	}
	
	
	/**
	 * Determines whether a TypeDeclaration has a superclass.
	 * @param typeDecl		the TypeDeclaration
	 * @return				true, if typeDecl has a superclass, false otherwise
	 */
	def protected static hasSuperClass(TypeDeclaration typeDecl) {
		return typeDecl.superclassType !== null
	}
	
	/**
	 * Determines whether a list of ASTNode's first element's visibility is 'private'.
	 * Note: Only works if the given list of ASTNodes' first element if either a FieldDeclaration, or a MethodDeclaration. Returns false otherwise.
	 * @param target		the list of ASTNodes
	 * @return				true, if target's first element's visibility if 'private', false otherwise
	 */
	def protected static isPrivate(List<? extends ASTNode> target) {
		if (target.head instanceof FieldDeclaration) {
			return Modifier.isPrivate( (target.head as FieldDeclaration).getModifiers())
		} else if(target.head instanceof MethodDeclaration) {
			return Modifier.isPrivate( (target.head as MethodDeclaration).getModifiers())
		}
		false
	}
	
	/**
	 * Gets all the references from a TypeDeclarations to the first element given list of ASTNodes.
	 * Note: Only works if the first element of the given list is either a FieldDeclaration, or a MethodDeclaration. Returns an empty list otherwise.
	 * @param target		the list of ASTNodes
	 * @param typeDecl		the TypeDeclaration
	 * @return				the references to the first element of target
	 */
	def protected static references(List<?extends ASTNode> target, TypeDeclaration typeDecl) {
		val bodyDeclarations = typeDecl.bodyDeclarations
		val List<ASTNode> refs = newArrayList
		
		if (target.head instanceof FieldDeclaration) {
			val fieldDecl = target.head as FieldDeclaration
			val fragments = fieldDecl.fragments as List<VariableDeclarationFragment>
			for(fragment : fragments) {
				val binding = fragment.resolveBinding
				for(declaration : bodyDeclarations) {
					val visitor = new ASTVisitor() {
						override visit(SimpleName name) {
							if (name.resolveBinding.isEqualTo(binding) && name != fragment.name) {
								refs.add(name)
							}
							return true
						}
					}
					(declaration as ASTNode).accept(visitor)
				}
			}
		} else if (target.head instanceof MethodDeclaration) {
			val methodDecl = target.head as MethodDeclaration
			val binding = methodDecl.resolveBinding
			for(declaration : bodyDeclarations) {
				val visitor = new ASTVisitor() {
					override visit(SimpleName name) {
						if (name.resolveBinding.isEqualTo(binding) && name != methodDecl.name) {
							refs.add(name)
						}
						return true
					}
				}
				(declaration as ASTNode).accept(visitor)
			}
		}
		refs
	}
	
	/**
	 * Determines whether a given identifier is used as a FieldDeclaration's identifier in a TypeDeclaration.
	 * @param fragmentName		the identifier
	 * @param typeDecl			the TypeDeclaration
	 * @return					true, if fragmentName isn't used as an identifier , false otherwise
	 */
	def private static isUniqueFieldIn(String fragmentName, TypeDeclaration typeDecl) {
		typeDecl.bodyDeclarations.filter[it instanceof FieldDeclaration].forall[
			!((it as FieldDeclaration).fragments as List<VariableDeclarationFragment>).exists[
				it.name.identifier == fragmentName
			]
		]
	}
	
	/**
	 * Determines whether neither of the given identifiers is used as a FieldDeclaration's identifier in a TypeDeclaration.
	 * @param fragmentNames		the list of identifiers
	 * @param typeDecl			the TypeDeclaration
	 * @return					true, if none of fragmentNames used as an identifier , false otherwise
	 */
	def protected static isUniqueFieldIn(List<String> fragmentNames, TypeDeclaration typeDecl) {
		fragmentNames.forall[
			isUniqueFieldIn(it, typeDecl)
		]
	}
	
	/**
	 * Determines whether if a method exists with the same name and parameter types as the given name and parameter types in a TypeDeclaration.
	 * @param methodName		the method's name
	 * @param parameters		the method's parameters
	 * @param typeDecl			the TypeDeclaration
	 * @return					true, if there isn't a method with the same name and parameter, false otherwise
	 */
	def protected static isUniqueMethodIn(String methodName, List<SingleVariableDeclaration> parameters, TypeDeclaration typeDecl) {
		val methodsInClass = typeDecl.bodyDeclarations.filter[it instanceof MethodDeclaration]
				
		for (method : methodsInClass) {
			if ((method as MethodDeclaration).name.identifier == methodName && parameters.size == ((method as MethodDeclaration).parameters.size)) {
				if (parameters.size == 0) {
					return false
				}
				
				val it1 = parameters.iterator
				val it2 = ((method as MethodDeclaration).parameters as List<SingleVariableDeclaration>).iterator
				var boolean l = true
				while(it1.hasNext && l) {
					l = it1.next.type.toString == it2.next.type.toString
				}
				
				if (l) {
					return false
				}
			}
		}
		true
	}
	
	/**
	 * Gets all the FielDeclaration that have a reference inside the first element of the given list of ASTNodes' body, in a TypeDeclaration.
	 * Note: Only works if the fist element of the given list is a MethodDeclaration. Returns an empty list otherwise.
	 * @param target 		the list of ASTNodes
	 * @param typeDecl		the TypeDeclaration
	 * @return				the referenced FieldDeclarations
	 */
	def protected static accessedFieldsOfEnclosingClass(List<? extends ASTNode> target, TypeDeclaration typeDecl) {
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
							if(name.resolveBinding.isEqualTo(binding)) {
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
	
	/**
	 * Gets all the MethodDeclarations that have a reference inside the first element of the given list of ASTNodes' body, in a TypeDeclaration.
	 * Note: Only works if the fist element of the given list is a MethodDeclaration. Returns an empty list otherwise.
	 * @param target 		the list of ASTNodes
	 * @param typeDecl		the TypeDeclaration
	 * @return				the referenced MethodDeclarations
	 */
	def protected static accessedMethodsOfEnclosingClass(List<? extends ASTNode> target, TypeDeclaration typeDecl) {
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
						if(name.resolveBinding.isEqualTo(binding) && name != methodDecl.name) {
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
	
	/**
	 * Determines whether if a method exists with the same name and parameter types as the given name and parameter types in a one of the given TypeDeclaration's superclass.
	 * @param methodName		the method's name
	 * @param parameters		the method's parameters
	 * @param typeDecl			the TypeDeclaration
	 * @return					true, if there isn't a method with the same name and parameter, false otherwise
	 */
	def protected static isOverrideIn(String methodName, List<SingleVariableDeclaration> parameters, TypeDeclaration typeDecl){
		var superClassToCheck = typeDecl
		var found = false
		
		while (superClassToCheck.hasSuperClass && !found) {
			superClassToCheck = superClassToCheck.superClass
			found = !isUniqueMethodIn(methodName, parameters, superClassToCheck) && !Modifier.isPrivate(getMethodFromClass(methodName, parameters, superClassToCheck).getModifiers)
		}
		found
	}
	
	/**
	 * Gets the method with the same name and parameter types as the given name and parameter types from a first of the given TypeDeclaration's superclass, that has one.
	 * Note: Only works if such a method exists.
	 * @param methodName		the method's name
	 * @param parameters		the method's parameters
	 * @param typeDecl			the TypeDeclaration
	 * @return					the method with the same name and parameter types
	 */
	def protected static overridenMethodFrom(String methodName, List<SingleVariableDeclaration> parameters, TypeDeclaration typeDecl) {
		var superClassToCheck = typeDecl
		var found = false
		var MethodDeclaration method
		while (superClassToCheck.hasSuperClass && !found) {
			superClassToCheck = superClassToCheck.superClass
			if(!isUniqueMethodIn(methodName, parameters, superClassToCheck)) {
				found = true
				method = getMethodFromClass(methodName, parameters, superClassToCheck)
			}
		}
		method
	}
	
	/** 
	 * Gets the FieldDeclaration from a TypeDeclaration with the given list of identifiers.
	 * @param fragmentNames		the list of identifiers
	 * @param typeDecl			the TypeDeclaration
	 * @return					the FieldDeclaration with the given list of identifiers
	 */
	def protected static getFieldFromClass(List<String> fragmentNames, TypeDeclaration typeDecl) {
		typeDecl.bodyDeclarations.findFirst[
			val iter = fragmentNames.iterator
			it instanceof FieldDeclaration && ((it as FieldDeclaration).fragments as List<VariableDeclarationFragment>).forall[
				if (iter.hasNext){
					it.name.identifier == iter.next
				} else {
					false
				}
			]
		] as FieldDeclaration
	}
	
	/** 
	 * Gets the MethodDeclaration from a TypeDeclaration with the given name and parameter types.
	 * @param methodName		the visibility to be examined
	 * @param parameters		the visibility that targetVisibility will be compared to
	 * @param typeDecl			the TypeDeclaration
	 * @return					the MethodDeclaration with the given name and parameter types
	 */
	def protected static getMethodFromClass(String methodName, List<SingleVariableDeclaration> parameters, TypeDeclaration typeDecl) {
		val methodsInClass = typeDecl.bodyDeclarations.filter[it instanceof MethodDeclaration]
		var MethodDeclaration result

		for(method : methodsInClass) {
			if ((method as MethodDeclaration).name.identifier == methodName && parameters.size == ((method as MethodDeclaration).parameters.size)) {
				if(parameters.size == 0) {
					result = method as MethodDeclaration
				}
				
				val it1 = parameters.iterator
				val it2 = ((method as MethodDeclaration).parameters as List<SingleVariableDeclaration>).iterator
				var boolean l = true
				while(it1.hasNext && l) {
					l = it1.next.type.toString == it2.next.type.toString
				}
				
				if (l) {
					result = method as MethodDeclaration	
				}
			}
		}
		result
	}
	
	/** 
	 * Determines whether targetVisibility is less visible than actualVisibility
	 * @param targetVisibility		the visibility to be examined
	 * @param actualVisibility		the visibility that targetVisibility will be compared to
	 * @return						true, if targetVisibility is less visible than actualVisibility, false otherwise
	 */
	def protected static isLessVisible(Visibility targetVisibility, Visibility actualVisibility) {
		if ((actualVisibility == Visibility.PUBLIC && (targetVisibility == Visibility.PRIVATE || targetVisibility == Visibility.PACKAGE || targetVisibility == Visibility.PROTECTED)) ||
			actualVisibility == Visibility.PROTECTED && (targetVisibility == Visibility.PRIVATE || targetVisibility == Visibility.PACKAGE) ||
			actualVisibility == Visibility.PACKAGE && (targetVisibility == Visibility.PRIVATE) ) {
			true
		} else {
			false
		}
	}
	
	/** 
	 * Determines whether targetType is a subclass of actualType. Both are ITypeBindings.
	 * @param targetType		the targetType to be examined
	 * @param actualType		the type that targetType will be compared to
	 * @return					true, if targetType is a subclass of actualType, false otherwise
	 */
	def private static isSubClassOf(ITypeBinding targetType, ITypeBinding actualType) {
		var tmp = targetType
		var boolean l = targetType.isEqualTo(actualType)
		while (tmp.superclass !== null && !l) {
			tmp = tmp.superclass
			l = tmp.isEqualTo(actualType)
		}
		return l
	}
	
	/** 
	 * Determines whether targetType is a subtype of actualType. Both are org.eclipse.jdt.core.dom.Type.
	 * @param targetType		the targetType to be examined
	 * @param actualType		the type that targetType will be compared to
	 * @return					true, if targetType is a subtype of actualType, false otherwise
	 */
	def protected static isSubTypeOf(Type targetType, Type actualType) {
		if (targetType.isPrimitiveType && actualType.isPrimitiveType) {
			targetType.toString == actualType.toString
		} else if (targetType.arrayType && actualType.arrayType) {
			if ((targetType as ArrayType).getDimensions != (actualType as ArrayType).getDimensions ) {
				false
			} else {
				if((targetType as ArrayType).elementType.isPrimitiveType && (actualType as ArrayType).elementType.isPrimitiveType) {
					(targetType as ArrayType).elementType.toString == (actualType as ArrayType).elementType.toString
				} else {
					targetType.resolveBinding.isSubClassOf(actualType.resolveBinding)
				}
			}
		} else if (targetType.simpleType && actualType.simpleType) {
			targetType.resolveBinding.isSubClassOf(actualType.resolveBinding)
		} else {
			false
		}
	}
	
	/**
	 * 
	 * @param name
	 * @param typeDecl
	 * @return
	 */
	def private static getTypeOfFieldOrVarDeclOfName(Name name, TypeDeclaration typeDecl) {
		val binding = if (name instanceof QualifiedName) {
			name.qualifier.resolveBinding
		} else if (name instanceof SimpleName) {
			name.resolveBinding
		}
		
		val List<ASTNode> result = newArrayList
		typeDecl.bodyDeclarations.exists[
			val visitor = new ASTVisitor() {
				public var boolean found = false
				
				override visit(SimpleName name) {
					if(name.resolveBinding.isEqualTo(binding) && (Utils.getFieldDeclaration(name) !== null || Utils.getVariableDeclaration(name) !== null) ) {
						found = true
						if(Utils.getFieldDeclaration(name) !== null) {
							result.add(Utils.getFieldDeclaration(name))
						} else {
							result.add(Utils.getVariableDeclaration(name))
						}
						return false
					}
					return true
				}
			}
			(it as ASTNode).accept(visitor)
			return visitor.found
		]
		
		if(!result.empty && result.get(0) instanceof FieldDeclaration) {
			return (result.get(0) as FieldDeclaration).type
		} else if (!result.empty && result.get(0) instanceof VariableDeclarationStatement) {
			return (result.get(0) as VariableDeclarationStatement).type
		}
	}
	
	/**
	 * Gets the field the is referred by an ASTNode.
	 * Note: Only works if the reference is a SimpleName, and referring to a Field. Returns null otherwise.
	 * @param reference		the ASTNode
	 * @return 				the referred FieldDeclaration
	 */
	def protected static referredField(ASTNode reference) {
		if(reference instanceof SimpleName) {
			val binding = (reference as SimpleName).resolveBinding
			for(typeDecl : allTypeDeclarationInWorkSpace) {
				for (declaration : typeDecl.bodyDeclarations) {
					if(declaration instanceof FieldDeclaration && ((declaration as FieldDeclaration).fragments as List<VariableDeclarationFragment>).exists[it.resolveBinding.isEqualTo(binding)] ) {
						return declaration as FieldDeclaration
					}
				}
			}
		}
		null
	}
	
	/**
	 * Gets all references to a FieldDeclaration in one of the given TypeDeclaration's superclass, that can potentially get violated of it gets overridden.
	 * @param methodName			the FieldDeclaration's fragment names
	 * @param typeDecl				the TypeDeclaration
	 * @return						all references that can potentially get violated if an override happens
	 */
	def static private referencesThatCanGetViolated(String fragmentName, TypeDeclaration typeDecl) {
		val List<ASTNode> references = newArrayList
		var TypeDeclaration superclassWithSameField = allTypeDeclarationInWorkSpace.findFirst[it.resolveBinding.qualifiedName == typeDecl.resolveBinding.qualifiedName]
		var boolean found = false
		while(superclassWithSameField.hasSuperClass && !found) {
			superclassWithSameField = superclassWithSameField.superClass	
			found = !isUniqueFieldIn(fragmentName, superclassWithSameField)
		}
		
		if (!found) {
			return references
		}
		
		val fieldInSuperClass = superclassWithSameField.bodyDeclarations.findFirst[
			it instanceof FieldDeclaration && ((it as FieldDeclaration).fragments as List<VariableDeclarationFragment>).exists[
				it.name.identifier == fragmentName
			]
		] as FieldDeclaration
		
		val List<ASTNode> a = newArrayList
		a.add(fieldInSuperClass)
		for (t : allTypeDeclarationInWorkSpace) {
			val refs = references(a, t)
			for (r : refs) {
				val refTypeDecl = Utils.getTypeDeclaration(r)
				if (refTypeDecl.resolveBinding.isEqualTo(typeDecl.resolveBinding) ||
					refTypeDecl.resolveBinding.isSubClassOf(typeDecl.resolveBinding) || 
					(r.parent instanceof QualifiedName && (getTypeOfFieldOrVarDeclOfName(r.parent as QualifiedName, refTypeDecl).resolveBinding.isEqualTo(typeDecl.resolveBinding) ||
					getTypeOfFieldOrVarDeclOfName(r.parent as QualifiedName, refTypeDecl).resolveBinding.isSubClassOf(typeDecl.resolveBinding))) ) {
					
					references.add(r)
				}
			}
		}
		references
	}
	
	/**
	 * Gets all references to a MethodDeclaration in one of the given TypeDeclaration's superclass, that can potentially get violated of it gets overridden.
	 * @param methodName			the MethodDeclaration's name
	 * @param methodParameters		the MethodDeclaration's parameters
	 * @param typeDecl				the TypeDeclaration
	 * @return						all references that can potentially get violated if an override happens
	 */
	def private static referencesThatCanGetViolated(String methodName, List<SingleVariableDeclaration> methodParameters, TypeDeclaration typeDecl) {
		val List<ASTNode> references = newArrayList
		var TypeDeclaration superclassWithSameMethod = allTypeDeclarationInWorkSpace.findFirst[it.resolveBinding.qualifiedName == typeDecl.resolveBinding.qualifiedName]
		var boolean found = false
		while(superclassWithSameMethod.hasSuperClass && !found) {
			superclassWithSameMethod = superclassWithSameMethod.superClass	
			found = !isUniqueMethodIn(methodName, methodParameters, superclassWithSameMethod)
		}
		
		if (!found) {
			return references
		}
		
		val methodInSuperClass = getMethodFromClass(methodName, methodParameters, superclassWithSameMethod)
		val List<ASTNode> a = newArrayList
		a.add(methodInSuperClass)
		for (t : allTypeDeclarationInWorkSpace) {
			val refs = references(a, t)
			for (r : refs) {
				val refTypeDecl = Utils.getTypeDeclaration(r)
				if (refTypeDecl.resolveBinding.isEqualTo(typeDecl.resolveBinding) ||
					refTypeDecl.resolveBinding.isSubClassOf(typeDecl.resolveBinding) || 
					( (r.parent as MethodInvocation).expression !== null && (getTypeOfFieldOrVarDeclOfName((r.parent as MethodInvocation).expression as Name, refTypeDecl).resolveBinding.isEqualTo(typeDecl.resolveBinding) ||
					getTypeOfFieldOrVarDeclOfName((r.parent as MethodInvocation).expression as Name, refTypeDecl).resolveBinding.isSubClassOf(typeDecl.resolveBinding))) ) {
						
					references.add(r)
				}
			}
		}
		references
	}
	
	/**
	 * Gets all the references to a FieldDeclaration, and separates them by their visibility.
	 * @param whichReferences		decides if whether the public, or non-public references are returned
	 * @param fragmentNames			the FieldDeclaration's fragment names
	 * @param targetTypeDecl		the FieldDeclaration's TypeDeclaration
	 * @return						if whichReferences equals "public", the references that can get accessed via public interface are returned (list of ASTNodes)
	 * 								if whichReferences equals "nonPublic", the references the cannot get accessed via public interface are returned (list of ASTNodes)
	 */
	def private static references(String whichReferences, List<String> fragmentNames, TypeDeclaration targetTypeDecl) {
		val List<ASTNode> publicReferences = newArrayList
		val List<ASTNode> nonPublicReferences = newArrayList
		
		for(fragmentName : fragmentNames) {
			val allReferences = referencesThatCanGetViolated(fragmentName, targetTypeDecl)
			val Queue<MethodDeclaration> methodsToCheck = newLinkedList
			
			for(ref : allReferences) {
				if(Utils.getMethodDeclaration(ref) !== null && Utils.getMethodDeclaration(ref).visibility == Visibility.PUBLIC) {
					publicReferences.add(ref)
				} else if (Utils.getMethodDeclaration(ref) !== null && Utils.getMethodDeclaration(ref).visibility != Visibility.PUBLIC){
					methodsToCheck.add(Utils.getMethodDeclaration(ref))
					
					while(!methodsToCheck.empty) {
						val method = methodsToCheck.remove
						var List<ASTNode> methodRefs = newArrayList
						for (t : allTypeDeclarationInWorkSpace) {
							val List<ASTNode> tmp = newArrayList
							tmp.add(method)
							methodRefs.addAll(references(tmp, t))
						}
						if(!methodRefs.empty) {
							for(methodRef : methodRefs) {
								if(Utils.getMethodDeclaration(methodRef) !== null && Utils.getMethodDeclaration(methodRef).visibility == Visibility.PUBLIC) {
									publicReferences.add(ref)
								} else if (Utils.getMethodDeclaration(methodRef) !== null && Utils.getMethodDeclaration(methodRef).visibility != Visibility.PUBLIC) {
									methodsToCheck.add(Utils.getMethodDeclaration(methodRef))
								} else if(Utils.getMethodDeclaration(methodRef) === null) {
									publicReferences.add(ref)
								}
							}
						} else {
							if(!nonPublicReferences.exists[it == ref]) {
								nonPublicReferences.add(ref)
							}
						}
					}
				} else if(Utils.getMethodDeclaration(ref) === null) {
					publicReferences.add(ref)
				}
			}
		}
		
		if(whichReferences == "public") {
			return publicReferences
		} else if(whichReferences == "nonPublic") {
			return nonPublicReferences
		}
	}
	
	/**
	 * Gets all the references to a MethodDeclaration, and separates them by their visibility.
	 * @param whichReferences		decides if whether the public, or non-public references are returned
	 * @param methodName			the MethodDeclaration's name
	 * @param mathodParameters		the MethodDeclaration's parameters
	 * @param targetTypeDecl		the MethodDeclaration's TypeDeclaration
	 * @return						if whichReferences equals "public", the references that can get accessed via public interface are returned (list of ASTNodes)
	 * 								if whichReferences equals "nonPublic", the references the cannot get accessed via public interface are returned (list of ASTNodes)
	 */
	def private static references(String whichReferences, String methodName, List<SingleVariableDeclaration> methodParameters,TypeDeclaration targetTypeDecl) {
		val List<ASTNode> publicReferences = newArrayList
		val List<ASTNode> nonPublicReferences = newArrayList
		
		val allReferences = referencesThatCanGetViolated(methodName, methodParameters, targetTypeDecl)
		val Queue<MethodDeclaration> methodsToCheck = newLinkedList
		
		for(ref : allReferences) {
			if(Utils.getMethodDeclaration(ref) !== null && Utils.getMethodDeclaration(ref).visibility == Visibility.PUBLIC) {
				publicReferences.add(ref)
			} else if (Utils.getMethodDeclaration(ref) !== null && Utils.getMethodDeclaration(ref).visibility != Visibility.PUBLIC){
				methodsToCheck.add(Utils.getMethodDeclaration(ref))
				
				while(!methodsToCheck.empty) {
					val method = methodsToCheck.remove
					var List<ASTNode> methodRefs = newArrayList
					for (t : allTypeDeclarationInWorkSpace) {
						val List<ASTNode> tmp = newArrayList
						tmp.add(method)
						methodRefs.addAll(references(tmp, t))
					}
					
					if(!methodRefs.empty) {
						for(methodRef : methodRefs) {
							if(Utils.getMethodDeclaration(methodRef) !== null && Utils.getMethodDeclaration(methodRef).visibility == Visibility.PUBLIC) {
								publicReferences.add(ref)
							} else if (Utils.getMethodDeclaration(methodRef) !== null && Utils.getMethodDeclaration(methodRef).visibility != Visibility.PUBLIC) {
								methodsToCheck.add(Utils.getMethodDeclaration(methodRef))
							} else if(Utils.getMethodDeclaration(methodRef) === null) {
								publicReferences.add(ref)
							}
						}
					} else {
						if(!nonPublicReferences.exists[it == ref]) {
							nonPublicReferences.add(ref)
						}
					}
				}
			} else if(Utils.getMethodDeclaration(ref) === null) {
				publicReferences.add(ref)
			}
		}
		
		if(whichReferences == "public") {
			return publicReferences
		} else if(whichReferences == "nonPublic") {
			return nonPublicReferences
		}
	}
	
	/**
	 * Gets all references to a FieldDeclaration that cannot get accessed via public interface.
	 * @param fragmentNames				the FieldDeclaration's fragment names
	 * @param targetTypeDeclaration		the FieldDeclaration's TypeDeclaration
	 * @return							list of ASTNodes
	 */
	def protected static nonPublicReferences(List<String> fragmentNames, TypeDeclaration targetTypeDecl) {
		references("nonPublic", fragmentNames, targetTypeDecl)
	}
	
	/**
	 * Gets all subclasses of a TypeDeclaration.
	 * @param typeDecl		the TypeDeclaration
	 * @return				all subclasses of typeDecl (list of org.eclipse.jdt.core.dom.TypeDeclaration)
	 */
	def protected static getAllSubClasses(TypeDeclaration typeDecl) {
		val binding = typeDecl.resolveBinding
		val List<TypeDeclaration> subClasses = newArrayList
		
		allTypeDeclarationInWorkSpace.forEach[
			if(it.resolveBinding.isSubClassOf(binding) && typeDecl != it) {
				subClasses.add(it)
			}
		]
		subClasses
	}
	
	/**
	 * Gets all MethodDeclaration with the same name and parameter types as the given name and parameter types from the given TypeDeclaration's subclasses.
	 * @param methodName				the identifier of the method
	 * @param methodParameters			the list of parameters of the method
	 * @param targetTypeDeclaration 	the TypeDeclaration
	 * @return							list of MethodDeclarations
	 */
	def protected static overridesOf(String methodName, List<SingleVariableDeclaration> methodParameters, TypeDeclaration targetTypeDeclaration) {
		val subClasses = targetTypeDeclaration.allSubClasses
		val List<MethodDeclaration> overriddenMethods = newArrayList
		subClasses.forEach[
			if(!isUniqueMethodIn(methodName, methodParameters, it)) {
				overriddenMethods.add(getMethodFromClass(methodName, methodParameters, it))
			}
		]
		overriddenMethods
	}
}
