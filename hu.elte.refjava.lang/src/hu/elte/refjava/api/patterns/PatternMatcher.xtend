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
import java.lang.reflect.Type
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
import org.eclipse.jdt.core.dom.VariableDeclarationFragment
import org.eclipse.jdt.core.dom.VariableDeclarationStatement
import org.eclipse.xtext.EcoreUtil2

class PatternMatcher {
	
	ArrayList<ASTNode> modifiedTarget
	val Pattern pattern
	Map<String, List<? extends ASTNode>> bindings = newHashMap
	Map<String, String> nameBindings
	Map<String, Type> typeBindings
	Map<String, List<Pair<Type, String>>> parameterBindings
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
	
	def match(Pattern targetPattern, List<? extends ASTNode> target, String typeRefString) {
		bindings.clear
		if (typeRefString !== null) {
			val tmp = typeRefString.split("\\|")
			this.typeReferenceQueue = newLinkedList
			this.typeReferenceQueue.addAll(tmp)
		}
		return doMatchChildren(targetPattern.patterns, target)
	}

	//this function gets called during the matching
	def match(List<? extends ASTNode> target, Map<String, String> nameBindings, Map<String, Type> typeBindings, Map<String, List<Pair<Type, String>>> parameterBindings, String typeRefString) {
		this.nameBindings = nameBindings
		this.typeBindings = typeBindings
		this.parameterBindings = parameterBindings
		
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
		bindings.put(multiMetavar.name, nodes)
		true
	}
	
	def private dispatch boolean doMatch(PBlockExpression blockPattern, Block block) {
		doMatchChildren(blockPattern.expressions, block.statements)
	}
	
	//constructor call matching
	def private dispatch boolean doMatch(PConstructorCall constCall, ClassInstanceCreation classInstance) {
		
		//matching constructor call name
		var boolean nameCheck
		if (constCall.metaName !== null) {
			//TODO
			nameCheck = true
		} else {
			nameCheck = constCall.name == classInstance.type.toString
		}
		
		//matching constructor call's methods
		var boolean anonClassCheck
		if (classInstance.anonymousClassDeclaration !== null && constCall.elements !== null) {
			//if (constCall.elements.size != classInstance.anonymousClassDeclaration.bodyDeclarations.size) {
				//return false
			//} else {
				anonClassCheck = doMatchChildren(constCall.elements, classInstance.anonymousClassDeclaration.bodyDeclarations)
			//}	
		} else {
			//TODO
			anonClassCheck = true
		}
		
		return nameCheck && anonClassCheck
	}
	
	//method matching
	def private dispatch boolean doMatch(PMethodDeclaration pMethodDecl, MethodDeclaration methodDecl) {
		
		//matching method name
		var boolean nameCheck
		if(pMethodDecl.prefix.metaName !== null) {
			//TODO
			nameCheck = true
		} else {
			nameCheck = pMethodDecl.prefix.name == methodDecl.name.identifier
		}
		
		//matching method visibility
		var boolean visibilityCheck 
		val modifiers = methodDecl.getModifiers
		switch pMethodDecl.prefix.visibility {
			case PUBLIC: visibilityCheck = Modifier.isPublic(modifiers)
			case PRIVATE: visibilityCheck = Modifier.isPrivate(modifiers)
			case PROTECTED: visibilityCheck = Modifier.isProtected(modifiers)
			default: visibilityCheck = modifiers.bitwiseAnd(Modifier.PROTECTED) == 0 && modifiers.bitwiseAnd(Modifier.PRIVATE) == 0 && modifiers.bitwiseAnd(Modifier.PUBLIC) == 0
		}
		
		//matching method return value
		var boolean returnCheck
		if(pMethodDecl.prefix.metaType !== null) {
			//TODO
			returnCheck = true
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
			//TODO
			parameterCheck = true
		}
		
		//matching method body
		val boolean bodyCheck = doMatch(pMethodDecl.body, methodDecl.body)
		
		return nameCheck && visibilityCheck && parameterCheck && returnCheck && bodyCheck
	}
	
	//method invocation matching
	def private dispatch boolean doMatch(PMemberFeatureCall featureCall, ExpressionStatement expStatement) {
		if (expStatement.expression instanceof MethodInvocation) {
			val methodInv = expStatement.expression as MethodInvocation
			
			//matching method invocation name
			var boolean nameCheck
			if (featureCall.feature !== null) {
				nameCheck = featureCall.feature == methodInv.name.identifier
			} else {
				//TODO
				nameCheck = true
			}
			
			//matching method invocation parameters
			var boolean parameterCheck
			if(featureCall.memberCallArguments !== null) {
				//TODO
				parameterCheck = true
			} else {
				//TODO
				parameterCheck = true
			}
			
			//matching method invocation expression
			val boolean expressionCheck = doMatch(featureCall.memberCallTarget, methodInv.expression)
			
			return nameCheck && parameterCheck && expressionCheck
		} else {
			return false
		}
	}
	
	//variable declaration matching
	def private dispatch boolean doMatch(PVariableDeclaration varDecl, VariableDeclarationStatement varDeclStatement) {
		
		//matching variable declaration name
		var boolean nameCheck
		if (varDecl.metaName !== null) {
			//TODO
			nameCheck = true
		} else {
			nameCheck = varDecl.name == (varDeclStatement.fragments.head as VariableDeclarationFragment).name.identifier
		}
		
		//matching variable declaration type
		var boolean typeCheck
		if(varDecl.type !== null) {
			typeCheck = varDeclStatement.type.resolveBinding.qualifiedName == typeReferenceQueue.remove
		} else {
			//TODO
			typeCheck = true
		}
		
		return nameCheck && typeCheck
	}
	
	def private dispatch boolean doMatch(PVariableDeclaration varDecl, FieldDeclaration fieldDecl) {
		
		//matching field declaration name
		var boolean nameCheck
		if (varDecl.metaName !== null) {
			//TODO
			nameCheck = true
		} else {
			nameCheck = varDecl.name == (fieldDecl.fragments.head as VariableDeclarationFragment).name.identifier
		}
		
		//matching field declaration visibility
		var boolean visibilityCheck
		val modifiers = fieldDecl.getModifiers
		switch varDecl.visibility {
			case PUBLIC: visibilityCheck = Modifier.isPublic(modifiers)
			case PRIVATE: visibilityCheck = Modifier.isPrivate(modifiers)
			case PROTECTED: visibilityCheck = Modifier.isProtected(modifiers)
			default: visibilityCheck = modifiers.bitwiseAnd(Modifier.PROTECTED) == 0 && modifiers.bitwiseAnd(Modifier.PRIVATE) == 0 && modifiers.bitwiseAnd(Modifier.PUBLIC) == 0
		}
		
		//matching field declaration type
		var boolean typeCheck
		if(varDecl.type !== null) {
			typeCheck = fieldDecl.type.resolveBinding.qualifiedName == typeReferenceQueue.remove
		} else {
			//TODO
			typeCheck = true
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
		
		var List<PExpression> preTargetExpression = patterns.clone.takeWhile[ !(it instanceof PTargetExpression) ].toList.reverse
		var List<PExpression> postTargetExpression = patterns.clone.reverse.takeWhile[ !(it instanceof PTargetExpression) ].toList.reverse
		
		val List<?super ASTNode> targetEnvironment = newArrayList
		targetEnvironment.addAll( (selectedNodes.head.parent as Block).statements )
		
		var List<ASTNode> preSelectedNodes = (targetEnvironment as List<?extends ASTNode>).clone.takeWhile[ it != selectedNodes.head ].toList.reverse
		var List<ASTNode> postSelectedNodes = (targetEnvironment as List<?extends ASTNode>).clone.reverse.takeWhile[ it != selectedNodes.last ].toList.reverse
		
		var Boolean pre
		var Boolean post
		
		if (!preTargetExpression.exists[ it instanceof PMetaVariable && (it as PMetaVariable).isMulti] ) {	
			val preSelectedNodesToMatch = preSelectedNodes.clone.take(preTargetExpression.size).toList
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
