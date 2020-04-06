package hu.elte.refjava.api.patterns

import hu.elte.refjava.lang.refJava.PBlockExpression
import hu.elte.refjava.lang.refJava.PConstructorCall
import hu.elte.refjava.lang.refJava.PExpression
import hu.elte.refjava.lang.refJava.PFeatureCall
import hu.elte.refjava.lang.refJava.PLambdaExpression
import hu.elte.refjava.lang.refJava.PMemberFeatureCall
import hu.elte.refjava.lang.refJava.PMetaVariable
import hu.elte.refjava.lang.refJava.PMethodDeclaration
import hu.elte.refjava.lang.refJava.PNameMetaVariable
import hu.elte.refjava.lang.refJava.PParameterMetaVariable
import hu.elte.refjava.lang.refJava.PTargetExpression
import hu.elte.refjava.lang.refJava.PTypeMetaVariable
import hu.elte.refjava.lang.refJava.PVariableDeclaration
import hu.elte.refjava.lang.refJava.Pattern
import java.lang.reflect.Type
import java.util.List
import java.util.Map
import java.util.Queue
import org.eclipse.jdt.core.dom.AST
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.Expression
import org.eclipse.jdt.core.dom.MethodDeclaration
import org.eclipse.jdt.core.dom.Modifier.ModifierKeyword
import org.eclipse.jdt.core.dom.rewrite.ASTRewrite

class ASTBuilder {

	Pattern pattern
	AST ast
	ASTRewrite rewrite
	Map<String, List<? extends ASTNode>> bindings
	Map<String, String> nameBindings
	Map<String, Type> typeBindings
	Map<String, List<Pair<Type, String>>> parameterBindings
	Queue<String> typeReferenceQueue
	
	new(Pattern pattern) {
		this.pattern = pattern
	}

	def getRewrite() {
		rewrite
	}
	
	def build(Pattern pattern, AST ast, Map<String, List<? extends ASTNode>> bindings, Map<String, String> nameBindings, Map<String, Type> typeBindings, Map<String, List<Pair<Type, String>>> parameterBindings, String typeRefString) {
		this.pattern = pattern
		build(ast, bindings, nameBindings, typeBindings, parameterBindings, typeRefString)
	}
	
	def buildNewInterface(PLambdaExpression lambdaExpr, AST ast, Map<String, List<? extends ASTNode>> bindings, Map<String, String> nameBindings, Map<String, Type> typeBindings, Map<String, List<Pair<Type, String>>> parameterBindings, String typeRefString){
		this.ast = ast
		
		val newInterface = ast.newTypeDeclaration
		newInterface.interface = true
		newInterface.name.identifier = "test"
		
		if(typeRefString !== null) {
			val tmp = typeRefString.split("\\|")
			this.typeReferenceQueue = newLinkedList
			this.typeReferenceQueue.addAll(tmp)
		}
		
		val lambdaExpressionBody = ((lambdaExpr.expression as PMemberFeatureCall).memberCallTarget as PConstructorCall).elements
		val newInterfaceBodyDeclarations = lambdaExpressionBody.doBuildPatterns
		
		newInterfaceBodyDeclarations.forEach[
			if(it instanceof MethodDeclaration) {
				(it as MethodDeclaration).body = null
			}
		]
		
		newInterface.bodyDeclarations.addAll(newInterfaceBodyDeclarations)
		return newInterface
	}

	def build(AST ast, Map<String, List<? extends ASTNode>> bindings, Map<String, String> nameBindings, Map<String, Type> typeBindings, Map<String, List<Pair<Type, String>>> parameterBindings, String typeRefString) {
		this.ast = ast
		this.rewrite = ASTRewrite.create(ast)
		this.bindings = bindings
		this.nameBindings = nameBindings
		this.typeBindings = typeBindings
		this.parameterBindings = parameterBindings
		
		if(typeRefString !== null) {
			val tmp = typeRefString.split("\\|")
			this.typeReferenceQueue = newLinkedList
			this.typeReferenceQueue.addAll(tmp)
		}
		
		if(pattern.empty) {
			return null
		} else {
			return pattern.patterns.doBuildPatterns
		}
		
	}

	//meta variable builder
	def private dispatch doBuild(PMetaVariable metaVar) {
		val binding = bindings.get(metaVar.name)
		if (!binding.empty) {
			val copies = binding.map[ASTNode.copySubtree(ast, it)]
			rewrite.createGroupNode(copies)
		}
	}
	
	//target expression builder
	def private dispatch doBuild(PTargetExpression targetExpr) {
		val binding = bindings.get("target")
		if (!binding.empty) {
			val copies = binding.map[ASTNode.copySubtree(ast, it)]
			rewrite.createGroupNode(copies)
		}
	}
	
	//constructor call builder
	def private dispatch doBuild(PConstructorCall constCall) {
		val class = ast.newClassInstanceCreation
		
		//adding constructor call name
		if (constCall.metaName !== null) {
			val name = (constCall.metaName as PNameMetaVariable).name
			class.type = ast.newSimpleType(ast.newName(nameBindings.get(name) ) )
		} else {
			class.type = ast.newSimpleType(ast.newName(constCall.name) )
		}
		
		//adding constructor call anonymous class declaration (body)
		if(constCall.anonInstance) {
			val anonClass = ast.newAnonymousClassDeclaration
			
			val buildDeclarations = constCall.elements.doBuildPatterns
			anonClass.bodyDeclarations.addAll(buildDeclarations)
			
			class.anonymousClassDeclaration = anonClass			
		}
		return class
		
	}
	
	//method builder
	def private dispatch ASTNode doBuild(PMethodDeclaration methodDecl) {
		val method = ast.newMethodDeclaration
		
		//adding method name
		if (methodDecl.prefix.metaName !== null) {
			val name = (methodDecl.prefix.metaName as PNameMetaVariable).name
			method.name.identifier = nameBindings.get(name)
		} else {
			method.name.identifier = methodDecl.prefix.name
		}
		
		//adding method visibility
		if(methodDecl.prefix.visibility !== null) {
			switch methodDecl.prefix.visibility {
				case PUBLIC: method.modifiers().add(ast.newModifier(ModifierKeyword.PUBLIC_KEYWORD))
				case PRIVATE: method.modifiers().add(ast.newModifier(ModifierKeyword.PRIVATE_KEYWORD))
				case PROTECTED: method.modifiers().add(ast.newModifier(ModifierKeyword.PROTECTED_KEYWORD))
				default: {}
			}
		}

		//adding method return type
		if(methodDecl.prefix.type !== null) {
			method.returnType2 = Utils.getTypeFromId(typeReferenceQueue.remove, ast)
		} else {
			val name = (methodDecl.prefix.metaType as PTypeMetaVariable).name
			method.returnType2 = Utils.getTypeFromId(typeBindings.get(name).typeName, ast)
		}

		//adding method parameters
		if (methodDecl.arguments.size > 0) {
			for(argument : methodDecl.arguments) {
				val typeName = typeReferenceQueue.remove
				
				val methodParameterDeclaration = ast.newSingleVariableDeclaration
				methodParameterDeclaration.type = Utils.getTypeFromId(typeName, ast)
				methodParameterDeclaration.name.identifier = argument.name
				method.parameters.add(methodParameterDeclaration)
			}
		} else if (methodDecl.metaArguments !== null) {
			val parameterList = parameterBindings.get((methodDecl.metaArguments as PParameterMetaVariable).name)
			for (parameter : parameterList) {
				val methodParameterDeclaration = ast.newSingleVariableDeclaration
				methodParameterDeclaration.type = Utils.getTypeFromId(parameter.key.toString, ast)
				methodParameterDeclaration.name.identifier = parameter.value
				method.parameters.add(methodParameterDeclaration)
			}
		}
		
		//adding method body
		val block = ast.newBlock
		val methodBody = (methodDecl.body as PBlockExpression).expressions
		var List<ASTNode> methodBodyList = newArrayList
		for(element : methodBody) {
			if(element instanceof PMetaVariable) {
				val binding = bindings.get( (element as PMetaVariable).name )
				val copies = binding.map[ASTNode.copySubtree(ast, it)]
				methodBodyList.addAll(copies)
			} else if (element instanceof PTargetExpression) {
				val binding = bindings.get( "target" )
				val copies = binding.map[ASTNode.copySubtree(ast, it)]
				methodBodyList.addAll(copies)
			} else {
				methodBodyList.add(element.doBuild)
			}
		}
		block.statements.addAll(methodBodyList)
		method.body = block
		return method
	}
	
	//variable declaration builder
	def private dispatch doBuild(PVariableDeclaration varDecl) {
		val fragment = ast.newVariableDeclarationFragment
		
		//adding variable name
		if(varDecl.metaName !== null) {
			fragment.name.identifier = nameBindings.get( (varDecl.metaName as PNameMetaVariable).name )
		} else {
			fragment.name.identifier = varDecl.name
		}
		
		val newVar = ast.newFieldDeclaration(fragment)
		
		//adding variable visibility
		if(varDecl.visibility !== null) {
			switch varDecl.visibility {
				case PUBLIC: newVar.modifiers().add(ast.newModifier(ModifierKeyword.PUBLIC_KEYWORD))
				case PRIVATE: newVar.modifiers().add(ast.newModifier(ModifierKeyword.PRIVATE_KEYWORD))
				case PROTECTED: newVar.modifiers().add(ast.newModifier(ModifierKeyword.PROTECTED_KEYWORD))
				default: {}
			}
		}
		
		//adding variable type
		if(varDecl.type !== null) {
			newVar.type = Utils.getTypeFromId(typeReferenceQueue.remove, ast)
		} else {
			val name = (varDecl.metaType as PTypeMetaVariable).name
			newVar.type = Utils.getTypeFromId(typeBindings.get(name).typeName, ast)
		}

		return newVar
	}
	
	//lambda expression builder
	def private dispatch ASTNode doBuild(PLambdaExpression lambdaExpr) {
		return doBuild(lambdaExpr.expression)
	}
	
	//method invocation (with expression) builder
	def private dispatch ASTNode doBuild(PMemberFeatureCall featureCall) {
		val methodInv = ast.newMethodInvocation
		
		//adding method invocation name
		if (featureCall.feature !== null) {
			methodInv.name.identifier = featureCall.feature
		} else {
			val name = (featureCall.metaFeature as PNameMetaVariable).name
			methodInv.name.identifier = nameBindings.get(name)
		}
		
		//adding method invocation parameters
		if(featureCall.memberCallArguments !== null) {
			val parameterList = parameterBindings.get((featureCall.memberCallArguments as PParameterMetaVariable).name)
			for (parameter : parameterList) {
				methodInv.arguments.add(ast.newSimpleName(parameter.value))
			}
		}
		
		//adding method invocation expression
		val buildInvocationExpression = featureCall.memberCallTarget.doBuild
		methodInv.expression = buildInvocationExpression as Expression
		
		val statement = ast.newExpressionStatement(methodInv)
		return statement
	}
	
	//method invocation (without expression) builder
	def private dispatch doBuild(PFeatureCall featureCall) {
		val methodInv = ast.newMethodInvocation
		
		//adding method invocation name
		methodInv.name.identifier = featureCall.feature
		
		//adding method parameters
		//TODO
		
		
		val statement = ast.newExpressionStatement(methodInv)
		return statement
	}
	
	//block builder
	def private dispatch doBuild(PBlockExpression blockPattern) {
		val block = ast.newBlock

		val builtStatements = blockPattern.expressions.doBuildPatterns
		block.statements.addAll(builtStatements)

		return block
	}
	
	def private List<ASTNode> doBuildPatterns(List<PExpression> patterns) {
		patterns.map[doBuild].filterNull.toList
	}
}
