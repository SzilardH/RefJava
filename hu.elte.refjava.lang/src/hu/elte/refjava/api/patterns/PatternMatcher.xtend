package hu.elte.refjava.api.patterns

import hu.elte.refjava.lang.refJava.PBlockExpression
import hu.elte.refjava.lang.refJava.PConstructorCall
import hu.elte.refjava.lang.refJava.PExpression
import hu.elte.refjava.lang.refJava.PMemberFeatureCall
import hu.elte.refjava.lang.refJava.PMetaVariable
import hu.elte.refjava.lang.refJava.PMethodDeclaration
import hu.elte.refjava.lang.refJava.PTargetExpression
import hu.elte.refjava.lang.refJava.PVariableDeclaration
import hu.elte.refjava.lang.refJava.Pattern
import hu.elte.refjava.lang.refJava.Visibility
import java.util.ArrayList
import java.util.List
import java.util.Map
import java.util.Queue
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.Block
import org.eclipse.jdt.core.dom.ClassInstanceCreation
import org.eclipse.jdt.core.dom.ExpressionStatement
import org.eclipse.jdt.core.dom.FieldDeclaration
import org.eclipse.jdt.core.dom.MethodDeclaration
import org.eclipse.jdt.core.dom.MethodInvocation
import org.eclipse.jdt.core.dom.Modifier
import org.eclipse.jdt.core.dom.SingleVariableDeclaration
import org.eclipse.jdt.core.dom.Type
import org.eclipse.jdt.core.dom.VariableDeclarationFragment
import org.eclipse.jdt.core.dom.VariableDeclarationStatement
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.jdt.core.dom.Expression
import hu.elte.refjava.lang.refJava.PFeatureCall

class PatternMatcher {
	
	ArrayList<ASTNode> modifiedTarget
	val Pattern pattern
	Map<String, List<? extends ASTNode>> bindings = newHashMap
	Map<String, String> nameBindings
	Map<String, Type> typeBindings
	Map<String, List<SingleVariableDeclaration>> parameterBindings
	Map<String, Visibility> visibilityBindings
	Map<String, List<Expression>> argumentBindings
	Queue<String> typeReferenceQueue
	
	new(Pattern pattern) {
		this.pattern = pattern
	}
	
	def getBindings() {
		bindings
	}
	
	def getModifiedTarget() {
		modifiedTarget
	}
	
	def match(Pattern targetPattern, List<? extends ASTNode> target, Map<String, String> nameBindings, Map<String, Type> typeBindings, Map<String, List<SingleVariableDeclaration>> parameterBindings, Map<String, Visibility> visibilityBindings, Map<String, List<Expression>> argumentBindings, String typeRefString) {
		bindings.clear
		this.nameBindings = nameBindings
		this.typeBindings = typeBindings
		this.parameterBindings = parameterBindings
		this.visibilityBindings = visibilityBindings
		this.argumentBindings = argumentBindings
		
		if (typeRefString !== null) {
			val tmp = typeRefString.split("\\|")
			this.typeReferenceQueue = newLinkedList
			this.typeReferenceQueue.addAll(tmp)
		}
		return doMatchChildren(targetPattern.patterns, target)
	}

	//this function gets called during the matching
	def match(List<? extends ASTNode> target, Map<String, String> nameBindings, Map<String, Type> typeBindings, Map<String, List<SingleVariableDeclaration>> parameterBindings, Map<String, Visibility> visibilityBindings, Map<String, List<Expression>> argumentBindings, String typeRefString) {
		this.nameBindings = nameBindings
		this.typeBindings = typeBindings
		this.parameterBindings = parameterBindings
		this.visibilityBindings = visibilityBindings
		this.argumentBindings = argumentBindings
		
		if (typeRefString !== null) {
			val tmp = typeRefString.split("\\|")
			this.typeReferenceQueue = newLinkedList
			this.typeReferenceQueue.addAll(tmp)
		}
		
		bindings.clear
		modifiedTarget = newArrayList
		modifiedTarget.addAll(target)
		
		val patterns = pattern.patterns
		val isTargetExists = EcoreUtil2.getAllContentsOfType(pattern, PTargetExpression).size > 0
		if (!isTargetExists) {
			doMatchChildren(patterns, target)	
		} else {
			doMatchChildrenWithTarget(patterns, target)			
		}
	}

	///////////////////////
	// doMatch overloads //
	///////////////////////
	def private dispatch doMatch(PMetaVariable metaVar, ASTNode anyNode) {
		bindings.put(metaVar.name, #[anyNode])
		true
	}
	
	def private dispatch doMatch(PMetaVariable multiMetavar, List<ASTNode> nodes) {
		if(multiMetavar.multi) {
			bindings.put(multiMetavar.name, nodes)
			true
		}
	}
	
	def private dispatch boolean doMatch(PBlockExpression blockPattern, Block block) {
		doMatchChildren(blockPattern.expressions, block.statements)
	}
	
	//constructor call matching
	def private dispatch boolean doMatch(PConstructorCall constCall, ClassInstanceCreation classInstance) {
		
		//matching constructor call name
		var boolean nameCheck
		if (constCall.metaName !== null) {
			val name = nameBindings.get((constCall.metaName as PMetaVariable).name)
			if (name === null) {
				val className = classInstance.type.toString
				nameBindings.put((constCall.metaName as PMetaVariable).name, className)
				nameCheck = true
			} else {
				nameCheck = name == classInstance.type.toString
			}
		} else {
			nameCheck = constCall.name == classInstance.type.toString
		}
		
		//matching constructor call's methods
		var boolean anonClassCheck
		if (classInstance.anonymousClassDeclaration !== null && constCall.elements !== null) {
			anonClassCheck = doMatchChildren(constCall.elements, classInstance.anonymousClassDeclaration.bodyDeclarations)	
		} else {
			anonClassCheck = true
		}
		
		return nameCheck && anonClassCheck
	}
	
	//method matching
	def private dispatch boolean doMatch(PMethodDeclaration pMethodDecl, MethodDeclaration methodDecl) {
		
		//matching method name
		var boolean nameCheck
		if(pMethodDecl.prefix.metaName !== null) {
			val name = nameBindings.get((pMethodDecl.prefix.metaName as PMetaVariable).name)
			if (name === null) {
				val methodName = methodDecl.name.identifier
				nameBindings.put((pMethodDecl.prefix.metaName as PMetaVariable).name, methodName)
				nameCheck = true
			} else {
				nameCheck = name == methodDecl.name.identifier
			}
		} else {
			nameCheck = pMethodDecl.prefix.name == methodDecl.name.identifier
		}
		
		//matching method visibility
		var boolean visibilityCheck
		val modifiers = methodDecl.getModifiers
		if (pMethodDecl.prefix.metaVisibility !== null) {
			val metaVarName = (pMethodDecl.prefix.metaVisibility as PMetaVariable).name
			if (visibilityBindings.get(metaVarName) === null) {
				switch modifiers {
					case Modifier.isPublic(modifiers) : visibilityBindings.put(metaVarName, Visibility.PUBLIC)
					case Modifier.isPrivate(modifiers) : visibilityBindings.put(metaVarName, Visibility.PRIVATE)
					case Modifier.isProtected(modifiers) : visibilityBindings.put(metaVarName, Visibility.PROTECTED)
					default : visibilityBindings.put(metaVarName, Visibility.PACKAGE)
				}
				visibilityCheck = true
			} else {
				switch visibilityBindings.get(metaVarName) {
					case PUBLIC: visibilityCheck = Modifier.isPublic(modifiers)
					case PRIVATE: visibilityCheck = Modifier.isPrivate(modifiers)
					case PROTECTED: visibilityCheck = Modifier.isProtected(modifiers)
					default: visibilityCheck = modifiers.bitwiseAnd(Modifier.PROTECTED) == 0 && modifiers.bitwiseAnd(Modifier.PRIVATE) == 0 && modifiers.bitwiseAnd(Modifier.PUBLIC) == 0
				}
			}
		} else {
			switch pMethodDecl.prefix.visibility {
				case PUBLIC: visibilityCheck = Modifier.isPublic(modifiers)
				case PRIVATE: visibilityCheck = Modifier.isPrivate(modifiers)
				case PROTECTED: visibilityCheck = Modifier.isProtected(modifiers)
				default: visibilityCheck = modifiers.bitwiseAnd(Modifier.PROTECTED) == 0 && modifiers.bitwiseAnd(Modifier.PRIVATE) == 0 && modifiers.bitwiseAnd(Modifier.PUBLIC) == 0
			}
		}
		

		//matching method return value
		var boolean returnCheck
		if(pMethodDecl.prefix.metaType !== null) {
			val type = typeBindings.get((pMethodDecl.prefix.metaType as PMetaVariable).name)
			if (type === null) {
				val returnType = methodDecl.returnType2
				typeBindings.put((pMethodDecl.prefix.metaType as PMetaVariable).name, returnType)
				returnCheck = true
			} else {
				returnCheck = type.resolveBinding.qualifiedName == methodDecl.returnType2.resolveBinding.qualifiedName
			}
		} else {
			returnCheck = methodDecl.returnType2.resolveBinding.qualifiedName == typeReferenceQueue.remove
		}
		
		//matching method parameters
		var boolean parameterCheck = true
		if (pMethodDecl.arguments.size > 0) {
			if (pMethodDecl.arguments.size != methodDecl.parameters.size) {
				parameterCheck = false
			} else {
				val argIt = pMethodDecl.arguments.iterator
				val paramIt = (methodDecl.parameters as List<SingleVariableDeclaration>).iterator
				while(argIt.hasNext && parameterCheck) {
					val arg = argIt.next
					val param = paramIt.next
					parameterCheck = param.name.identifier == arg.name && param.type.resolveBinding.qualifiedName == typeReferenceQueue.remove 
				}
			}
		} else if (pMethodDecl.metaArguments !== null) {
			val metaVar = pMethodDecl.metaArguments as PMetaVariable
			val parameters = parameterBindings.get((pMethodDecl.metaArguments as PMetaVariable).name)
			if (parameters === null) {
				parameterBindings.put(metaVar.name, methodDecl.parameters)
				parameterCheck = true
			} else {
				if (parameters.size != methodDecl.parameters.size) {
					parameterCheck = false
				} else {
					val it1 = parameters.iterator
					val it2 = (methodDecl.parameters as List<SingleVariableDeclaration>).iterator
					while(it1.hasNext && parameterCheck) {
						val param1 = it1.next
						val param2 = it2.next
						parameterCheck = param1.name.identifier == param2.name.identifier && param1.type.resolveBinding.qualifiedName == param2.type.resolveBinding.qualifiedName
					}
				}
			}
		} else {
			parameterCheck = methodDecl.parameters.size == 0
		}
		
		//matching method body
		val boolean bodyCheck = doMatch(pMethodDecl.body, methodDecl.body)
		
		return nameCheck && visibilityCheck && parameterCheck && returnCheck && bodyCheck
	}
	
	//method invocation matching (with expression)
	def private dispatch boolean doMatch(PMemberFeatureCall featureCall, ExpressionStatement expStatement) {
		if (expStatement.expression instanceof MethodInvocation) {
			val methodInv = expStatement.expression as MethodInvocation
			
			//matching method invocation name
			var boolean nameCheck
			if (featureCall.feature !== null) {
				nameCheck = featureCall.feature == methodInv.name.identifier
			} else {
				val name = nameBindings.get((featureCall.metaFeature as PMetaVariable).name)
				if (name === null) {
					val methodName = methodInv.name.identifier
					nameBindings.put((featureCall.metaFeature as PMetaVariable).name, methodName)
					nameCheck = true
				} else {
					nameCheck = name == methodInv.name.identifier
				}
			}
			
			//matching method invocation parameters
			var boolean argumentCheck = true
			if(featureCall.memberCallArguments !== null) {
				//TODO
				
				
				val metaVarName = (featureCall.memberCallArguments as PMetaVariable).name
				if (argumentBindings.get(metaVarName) ===  null) {
					argumentBindings.put(metaVarName, methodInv.arguments)
					argumentCheck = true
				} else {
					val arguments = argumentBindings.get(metaVarName)
					if(methodInv.arguments.size != arguments.size) {
						argumentCheck = false
					} else {
						//TODO
						argumentCheck = true
					}
				}
			} else {
				argumentCheck = methodInv.arguments.size == 0
			}
			
			//matching method invocation expression
			val boolean expressionCheck = doMatch(featureCall.memberCallTarget, methodInv.expression)
			
			return nameCheck && argumentCheck && expressionCheck
		} else {
			return false
		}
	}
	
	
	//method invocation matching (without expression)
	def private dispatch boolean doMatch(PFeatureCall featureCall, ExpressionStatement expStatement) {
		if (expStatement.expression instanceof MethodInvocation) {
			val methodInv = expStatement.expression as MethodInvocation
			
			//matching method invocation name
			var boolean nameCheck
			if (featureCall.feature !== null) {
				nameCheck = featureCall.feature == methodInv.name.identifier
			} else {
				val name = nameBindings.get((featureCall.metaFeature as PMetaVariable).name)
				if (name === null) {
					val methodName = methodInv.name.identifier
					nameBindings.put((featureCall.metaFeature as PMetaVariable).name, methodName)
					nameCheck = true
				} else {
					nameCheck = name == methodInv.name.identifier
				}
			}
			
			//matching method invocation parameters
			var boolean argumentCheck = true
			if(featureCall.featureCallArguments !== null) {
				//TODO
				val metaVarName = (featureCall.featureCallArguments as PMetaVariable).name
				if (argumentBindings.get(metaVarName) ===  null) {
					argumentBindings.put(metaVarName, methodInv.arguments)
					argumentCheck = true
				} else {
					val arguments = argumentBindings.get(metaVarName)
					if(methodInv.arguments.size != arguments.size) {
						argumentCheck = false
					} else {
						//TODO
						argumentCheck = true
					}
				}
			} else {
				argumentCheck = methodInv.arguments.size == 0
			}
			
			return nameCheck && argumentCheck
		} else {
			return false
		}
	}
	
	
	
	//variable declaration matching
	def private dispatch boolean doMatch(PVariableDeclaration varDecl, VariableDeclarationStatement varDeclStatement) {
		
		//matching variable declaration name
		var boolean nameCheck
		if (varDecl.metaName !== null) {
			val name = nameBindings.get((varDecl.metaName as PMetaVariable).name)
			if(name === null) {
				val varName = (varDeclStatement.fragments.head as VariableDeclarationFragment).name.identifier
				nameBindings.put((varDecl.metaName as PMetaVariable).name, varName)
				nameCheck = true
			} else {
				nameCheck = name == (varDeclStatement.fragments.head as VariableDeclarationFragment).name.identifier
			}
		} else {
			nameCheck = varDecl.name == (varDeclStatement.fragments.head as VariableDeclarationFragment).name.identifier
		}
		
		//matching variable declaration type
		var boolean typeCheck
		if(varDecl.type !== null) {
			typeCheck = varDeclStatement.type.resolveBinding.qualifiedName == typeReferenceQueue.remove
		} else {
			val type = typeBindings.get((varDecl.metaType as PMetaVariable).name)
			if (type === null) {
				val varType = varDeclStatement.type
				typeBindings.put((varDecl.metaType as PMetaVariable).name, varType)
				typeCheck = true
			} else {
				typeCheck = type.resolveBinding.qualifiedName == varDeclStatement.type.resolveBinding.qualifiedName
			}
		}
		
		return nameCheck && typeCheck
	}
	
	//field declaration matching
	def private dispatch boolean doMatch(PVariableDeclaration varDecl, FieldDeclaration fieldDecl) {
		
		//matching field declaration name
		var boolean nameCheck
		if (varDecl.metaName !== null) {
			val name = nameBindings.get((varDecl.metaName as PMetaVariable).name)
			if (name === null) {
				val fieldName = (fieldDecl.fragments.head as VariableDeclarationFragment).name.identifier
				nameBindings.put((varDecl.metaName as PMetaVariable).name, fieldName)
				nameCheck = true
			} else {
				nameCheck = name == (fieldDecl.fragments.head as VariableDeclarationFragment).name.identifier
			}
		} else {
			nameCheck = varDecl.name == (fieldDecl.fragments.head as VariableDeclarationFragment).name.identifier
		}
		
		//matching field declaration visibility
		var boolean visibilityCheck
		val modifiers = fieldDecl.getModifiers
		if (varDecl.metaVisibility !== null) {
			val metaVarName = (varDecl.metaVisibility as PMetaVariable).name
			if (visibilityBindings.get(metaVarName) === null) {
					switch modifiers {
					case Modifier.isPublic(modifiers) : visibilityBindings.put(metaVarName, Visibility.PUBLIC)
					case Modifier.isPrivate(modifiers) : visibilityBindings.put(metaVarName, Visibility.PRIVATE)
					case Modifier.isProtected(modifiers) : visibilityBindings.put(metaVarName, Visibility.PROTECTED)
					default : visibilityBindings.put(metaVarName, Visibility.PACKAGE)
				}
				visibilityCheck = true
			} else {
				switch visibilityBindings.get(metaVarName) {
					case PUBLIC: visibilityCheck = Modifier.isPublic(modifiers)
					case PRIVATE: visibilityCheck = Modifier.isPrivate(modifiers)
					case PROTECTED: visibilityCheck = Modifier.isProtected(modifiers)
					default: visibilityCheck = modifiers.bitwiseAnd(Modifier.PROTECTED) == 0 && modifiers.bitwiseAnd(Modifier.PRIVATE) == 0 && modifiers.bitwiseAnd(Modifier.PUBLIC) == 0
				}
			}
		} else {
			switch varDecl.visibility {
				case PUBLIC: visibilityCheck = Modifier.isPublic(modifiers)
				case PRIVATE: visibilityCheck = Modifier.isPrivate(modifiers)
				case PROTECTED: visibilityCheck = Modifier.isProtected(modifiers)
				default: visibilityCheck = modifiers.bitwiseAnd(Modifier.PROTECTED) == 0 && modifiers.bitwiseAnd(Modifier.PRIVATE) == 0 && modifiers.bitwiseAnd(Modifier.PUBLIC) == 0
			}
		}
		
		//matching field declaration type
		var boolean typeCheck
		if(varDecl.type !== null) {
			typeCheck = fieldDecl.type.resolveBinding.qualifiedName == typeReferenceQueue.remove
		} else {
			val type = typeBindings.get((varDecl.metaType as PMetaVariable).name)
			if (type === null) {
				val fieldType = fieldDecl.type
				typeBindings.put((varDecl.metaType as PMetaVariable).name, fieldType)
				typeCheck = true
			} else {
				typeCheck = type.resolveBinding.qualifiedName == fieldDecl.type.resolveBinding.qualifiedName
			}
		}
		
		return nameCheck && visibilityCheck && typeCheck
	}
	
	def private dispatch doMatch(PExpression anyOtherPattern, ASTNode anyOtherNode) {
		false
	}
	
	///////////////////////
	// children matching //
	///////////////////////
	def private doMatchChildren(List<PExpression> patterns, List<? extends ASTNode> nodes) {
		if (patterns.size == 1 && patterns.head instanceof PMetaVariable && (patterns.head as PMetaVariable).multi) {
			bindings.put("target", nodes)
			bindings.put((patterns.head as PMetaVariable).name , nodes)
			return true
		}
		
		if (!patterns.exists[it instanceof PMetaVariable && (it as PMetaVariable).multi] && nodes.size != patterns.size) {
			return false
		}
		
		val nIt = nodes.iterator
		for (var int i = 0; i < patterns.size; i++) {
			if( !(patterns.get(i) instanceof PMetaVariable) || !(patterns.get(i) as PMetaVariable).multi ) {
				if (!doMatch(patterns.get(i), nIt.next)) {
					return false
				}
			} else {
				val preMultiMetavar = patterns.take(i).size
				val postMultiMetavar = patterns.drop(i + 1).size
				var List<ASTNode> matchingNodes = newArrayList
				var int j = 0
				
				while (j != nodes.size - (preMultiMetavar + postMultiMetavar) ) {
					matchingNodes.add(nIt.next)
					j++
				}
				
				if(!doMatch(patterns.get(i), matchingNodes)) {
					return false
				}
			}
		}
		bindings.put("target", nodes)
		true
	}
	
	def private doMatchChildrenWithTarget(List<PExpression> patterns, List<? extends ASTNode> selectedNodes) {
		if (patterns.size == 1 && patterns.head instanceof PTargetExpression) {
			bindings.put("target", selectedNodes)
			return true
		}
		
		var List<PExpression> preTargetExpression = patterns.clone.takeWhile[ !(it instanceof PTargetExpression) ].toList
		var List<PExpression> postTargetExpression = patterns.clone.reverse.takeWhile[ !(it instanceof PTargetExpression) ].toList.reverse
		
		val List<?super ASTNode> targetEnvironment = newArrayList
		targetEnvironment.addAll( (selectedNodes.head.parent as Block).statements )
		
		var List<ASTNode> preSelectedNodes = (targetEnvironment as List<?extends ASTNode>).clone.takeWhile[ it != selectedNodes.head ].toList
		var List<ASTNode> postSelectedNodes = (targetEnvironment as List<?extends ASTNode>).clone.reverse.takeWhile[ it != selectedNodes.last ].toList.reverse
		
		var boolean pre
		var boolean post

		if (!preTargetExpression.exists[ it instanceof PMetaVariable && (it as PMetaVariable).isMulti] ) {
			val preSelectedNodesToMatch = preSelectedNodes.clone.reverse.take(preTargetExpression.size).toList.reverse
			pre = doMatchChildren(preTargetExpression, preSelectedNodesToMatch)
			modifiedTarget.addAll(0, preSelectedNodesToMatch)
		} else {
			pre = doMatchChildren(preTargetExpression, preSelectedNodes)
			modifiedTarget.addAll(0, preSelectedNodes)
		}
		
		if (!postTargetExpression.exists[ it instanceof PMetaVariable && (it as PMetaVariable).isMulti] ) {
			val postSelectedNodesToMatch = postSelectedNodes.clone.take(postTargetExpression.size).toList	
			post = doMatchChildren(postTargetExpression, postSelectedNodesToMatch)
			modifiedTarget.addAll(postSelectedNodesToMatch)
		} else {
			post = doMatchChildren(postTargetExpression, postSelectedNodes)
			modifiedTarget.addAll(postSelectedNodes)
		}
		bindings.put("target", selectedNodes)
		return pre && post	
	}
}
