package hu.elte.refjava.api

import hu.elte.refjava.api.patterns.Utils
import java.lang.reflect.Modifier
import java.util.List
import java.util.Queue
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.ASTVisitor
import org.eclipse.jdt.core.dom.ArrayType
import org.eclipse.jdt.core.dom.Block
import org.eclipse.jdt.core.dom.ClassInstanceCreation
import org.eclipse.jdt.core.dom.ExpressionStatement
import org.eclipse.jdt.core.dom.FieldDeclaration
import org.eclipse.jdt.core.dom.ITypeBinding
import org.eclipse.jdt.core.dom.MethodDeclaration
import org.eclipse.jdt.core.dom.MethodInvocation
import org.eclipse.jdt.core.dom.Name
import org.eclipse.jdt.core.dom.QualifiedName
import org.eclipse.jdt.core.dom.SimpleName
import org.eclipse.jdt.core.dom.SingleVariableDeclaration
import org.eclipse.jdt.core.dom.Statement
import org.eclipse.jdt.core.dom.Type
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jdt.core.dom.VariableDeclarationFragment
import org.eclipse.jdt.core.dom.VariableDeclarationStatement

class Check {
	
	public static List<TypeDeclaration> allTypeDeclarationInWorkSpace
	
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
		nodes.forall[it instanceof VariableDeclarationStatement]
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
	
	//lambda checks	
	def static isFresh(String name) {
		!allTypeDeclarationInWorkSpace.exists[it.name.identifier == name]
	}
	
	def static generateNewName() {
		var int i = 1
		var newName = "newLambda"
		while(!isFresh(newName)) {
			newName = "newLambda" + i++
		}
		newName
	}
	
	def static references(TypeDeclaration typeDecl) {
		val List<ASTNode> refs = newArrayList
		val binding = typeDecl.name.resolveBinding
		
		allTypeDeclarationInWorkSpace.forEach[
			val visitor = new ASTVisitor() {
				override visit(SimpleName name) {
					if (name.resolveBinding.isEqualTo(binding) && name != typeDecl.name) {
						refs.add(name)
					}
					return true
				}
			}
			it.accept(visitor)
		]
		refs
	}
	
	def static contains(List<ASTNode> references, List<? extends ASTNode> target) {
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
		return false
	}
	
	//method or field property getters
	def static String getMethodName(List<? extends ASTNode> target) {
		if (target.head instanceof MethodDeclaration) {
			(target.head as MethodDeclaration).name.identifier
		}
	}
	
	def static List<String> getFragmentNames(List<? extends ASTNode> target) {
		if(target.head instanceof FieldDeclaration) {
			val fragments = (target.head as FieldDeclaration).fragments as List<VariableDeclarationFragment>
			var List<String> fragmentNames = newArrayList
			for(fragment : fragments) {
				fragmentNames.add(fragment.name.identifier)
			}
			fragmentNames
		} 
	}
	
	def dispatch static type(MethodDeclaration methodDecl) {
		methodDecl.returnType2
	}
	
	def dispatch static type(FieldDeclaration fieldDecl) {
		fieldDecl.type
	}
	
	def dispatch static Type type(List<? extends ASTNode> target) {
		if (target.head instanceof MethodDeclaration) {
			type(target.head)
		} else if (target.head instanceof FieldDeclaration) {
			type(target.head)
		}
	}
	
	def dispatch static visibility(FieldDeclaration fieldDecl) {
		val modifiers = fieldDecl.getModifiers
		switch modifiers {
			case modifiers.bitwiseAnd(Modifier.PUBLIC) > 0 : "public"
			case modifiers.bitwiseAnd(Modifier.PRIVATE) > 0 : "private"
			case modifiers.bitwiseAnd(Modifier.PROTECTED) > 0 : "protected"
			case modifiers.bitwiseAnd(Modifier.PROTECTED) == 0 && modifiers.bitwiseAnd(Modifier.PRIVATE) == 0 && modifiers.bitwiseAnd(Modifier.PUBLIC) == 0 : "default"
		}
	}
	
	def dispatch static visibility(MethodDeclaration methodDecl) {
		val modifiers = methodDecl.getModifiers
		switch modifiers {
			case modifiers.bitwiseAnd(Modifier.PUBLIC) > 0 : "public"
			case modifiers.bitwiseAnd(Modifier.PRIVATE) > 0 : "private"
			case modifiers.bitwiseAnd(Modifier.PROTECTED) > 0 : "protected"
			case modifiers.bitwiseAnd(Modifier.PROTECTED) == 0 && modifiers.bitwiseAnd(Modifier.PRIVATE) == 0 && modifiers.bitwiseAnd(Modifier.PUBLIC) == 0 : "default"
		}
	}
	
	def dispatch static String visibility(List<? extends ASTNode> target) {
		if(target.head instanceof MethodDeclaration) {
			visibility(target.head as MethodDeclaration)
		} else if (target.head instanceof FieldDeclaration) {
			visibility(target.head as FieldDeclaration)
		}
	}
	
	def dispatch static parameters(List<? extends ASTNode> target) {
		if(target.head instanceof MethodDeclaration) {
			(target.head as MethodDeclaration).parameters as List<SingleVariableDeclaration>
		}
	}
	
	def dispatch static parameters(MethodDeclaration methodDecl) {
		methodDecl.parameters as List<SingleVariableDeclaration>
	}
	
	
	
	//class checks
	def static enclosingClass(List<? extends ASTNode> target) {
		val typeDecl = Utils.getTypeDeclaration(target.head)
		allTypeDeclarationInWorkSpace.findFirst[it.resolveBinding.qualifiedName == typeDecl.resolveBinding.qualifiedName]
	}
	
	def static superClass(TypeDeclaration typeDecl) {
		allTypeDeclarationInWorkSpace.findFirst[it.resolveBinding.qualifiedName == typeDecl.superclassType.resolveBinding.qualifiedName]
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
	
	def private static isUniqueFieldIn(String fragmentName, TypeDeclaration typeDecl) {
		typeDecl.bodyDeclarations.filter[it instanceof FieldDeclaration].forall[
			!((it as FieldDeclaration).fragments as List<VariableDeclarationFragment>).exists[
				it.name.identifier == fragmentName
			]
		]
	}
	
	def static isUniqueFieldIn(List<String> fragmentNames, TypeDeclaration typeDecl) {
		fragmentNames.forall[
			isUniqueFieldIn(it, typeDecl)
		]
	}
	
	def static isUniqueMethodIn(String methodName, List<SingleVariableDeclaration> parameters, TypeDeclaration typeDecl) {
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
	
	def static isOverrideIn(String methodName, List<SingleVariableDeclaration> parameters, TypeDeclaration typeDecl){
		var superClassToCheck = typeDecl
		var found = false
		
		while (superClassToCheck.hasSuperClass && !found) {
			superClassToCheck = superClassToCheck.superClass
			found = !isUniqueMethodIn(methodName, parameters, superClassToCheck) && !Modifier.isPrivate(getMethodFromClass(methodName, parameters, superClassToCheck).getModifiers)
		}
		found
	}
	
	def static overridenMethodFrom(String methodName, List<SingleVariableDeclaration> parameters, TypeDeclaration typeDecl) {
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
	
	def private static getMethodFromClass(String methodName, List<SingleVariableDeclaration> parameters, TypeDeclaration typeDecl) {
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
	
	def static isLessVisible(String targetVisibility, String actualVisibility) {
		if ((actualVisibility == "public" && (targetVisibility == "private" || targetVisibility == "default" || targetVisibility == "protected")) ||
			actualVisibility == "protected" && (targetVisibility == "private" || targetVisibility == "default") ||
			actualVisibility == "default" && (targetVisibility == "private") ) {
			true
		} else {
			false
		}
	}
	
	def private static isSubClassOf(ITypeBinding targetType, ITypeBinding actualType) {
		var tmp = targetType
		var boolean l = targetType.isEqualTo(actualType)
		while (tmp.superclass !== null && !l) {
			tmp = tmp.superclass
			l = tmp.isEqualTo(actualType)
		}
		return l
	}
	
	def static isSubTypeOf(Type targetType, Type actualType) {
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
	
	def static referredField(ASTNode reference) {
		val binding = (reference as SimpleName).resolveBinding
		
		for(typeDecl : allTypeDeclarationInWorkSpace) {
			for (declaration : typeDecl.bodyDeclarations) {
				if(declaration instanceof FieldDeclaration && ((declaration as FieldDeclaration).fragments as List<VariableDeclarationFragment>).exists[it.resolveBinding.isEqualTo(binding)] ) {
					return declaration as FieldDeclaration
				}
			}
		}
		//error
	}
	
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
	
	def private static referencesThatCanGetViolated(String methodName, List<SingleVariableDeclaration> methodParameters, TypeDeclaration typeDecl) {
		val List<ASTNode> references = newArrayList
		var TypeDeclaration superclassWithSameField = allTypeDeclarationInWorkSpace.findFirst[it.resolveBinding.qualifiedName == typeDecl.resolveBinding.qualifiedName]
		var boolean found = false
		while(superclassWithSameField.hasSuperClass && !found) {
			superclassWithSameField = superclassWithSameField.superClass	
			found = !isUniqueMethodIn(methodName, methodParameters, superclassWithSameField)
		}
		
		if (!found) {
			return references
		}
		
		val methodInSuperClass = getMethodFromClass(methodName, methodParameters, superclassWithSameField)
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
	
	def private static references(String whichReferences, List<String> fragmentNames, TypeDeclaration targetTypeDecl) {
		val List<ASTNode> publicReferences = newArrayList
		val List<ASTNode> privateReferences = newArrayList
		
		for(fragmentName : fragmentNames) {
			val allReferences = referencesThatCanGetViolated(fragmentName, targetTypeDecl)
			val Queue<MethodDeclaration> methodsToCheck = newLinkedList
			
			for(ref : allReferences) {
				if(Utils.getMethodDeclaration(ref) !== null && Utils.getMethodDeclaration(ref).visibility != "private") {
					publicReferences.add(ref)
				} else if (Utils.getMethodDeclaration(ref) !== null && Utils.getMethodDeclaration(ref).visibility == "private"){
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
								if(Utils.getMethodDeclaration(methodRef) !== null && Utils.getMethodDeclaration(methodRef).visibility != "private") {
									publicReferences.add(ref)
								} else if (Utils.getMethodDeclaration(methodRef) !== null && Utils.getMethodDeclaration(methodRef).visibility == "private") {
									methodsToCheck.add(Utils.getMethodDeclaration(methodRef))
								} else if(Utils.getMethodDeclaration(methodRef) === null) {
									publicReferences.add(ref)
								}
							}
						} else {
							if(!privateReferences.exists[it == ref]) {
								privateReferences.add(ref)
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
		} else if(whichReferences == "private") {
			return privateReferences
		}
	}
	
	def private static references(String whichReferences, String methodName, List<SingleVariableDeclaration> methodParameters,TypeDeclaration targetTypeDecl) {
		val List<ASTNode> publicReferences = newArrayList
		val List<ASTNode> privateReferences = newArrayList
		
		val allReferences = referencesThatCanGetViolated(methodName, methodParameters, targetTypeDecl)
		val Queue<MethodDeclaration> methodsToCheck = newLinkedList
		
		for(ref : allReferences) {
			if(Utils.getMethodDeclaration(ref) !== null && Utils.getMethodDeclaration(ref).visibility != "private") {
				publicReferences.add(ref)
			} else if (Utils.getMethodDeclaration(ref) !== null && Utils.getMethodDeclaration(ref).visibility == "private"){
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
							if(Utils.getMethodDeclaration(methodRef) !== null && Utils.getMethodDeclaration(methodRef).visibility != "private") {
								publicReferences.add(ref)
							} else if (Utils.getMethodDeclaration(methodRef) !== null && Utils.getMethodDeclaration(methodRef).visibility == "private") {
								methodsToCheck.add(Utils.getMethodDeclaration(methodRef))
							} else if(Utils.getMethodDeclaration(methodRef) === null) {
								publicReferences.add(ref)
							}
						}
					} else {
						if(!privateReferences.exists[it == ref]) {
							privateReferences.add(ref)
						}
					}
				}
			} else if(Utils.getMethodDeclaration(ref) === null) {
				publicReferences.add(ref)
			}
		}
		
		if(whichReferences == "public") {
			return publicReferences
		} else if(whichReferences == "private") {
			return privateReferences
		}
	}
	
	def static publicReferences(List<String> fragmentNames, TypeDeclaration targetTypeDecl) {
		references("public", fragmentNames, targetTypeDecl)
	}
	
	def static publicReferences(String methodName, List<SingleVariableDeclaration> methodParameters, TypeDeclaration targetTypeDeclaration) {
		references("public", methodName, methodParameters, targetTypeDeclaration)
	}
	
	def static privateReferences(List<String> fragmentNames, TypeDeclaration targetTypeDecl) {
		references("private", fragmentNames, targetTypeDecl)
	}
	
	
	
}
