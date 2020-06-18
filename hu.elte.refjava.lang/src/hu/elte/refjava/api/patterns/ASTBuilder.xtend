package hu.elte.refjava.api.patterns

import hu.elte.refjava.api.Check
import hu.elte.refjava.lang.refJava.PBlockExpression
import hu.elte.refjava.lang.refJava.PConstructorCall
import hu.elte.refjava.lang.refJava.PExpression
import hu.elte.refjava.lang.refJava.PFeatureCall
import hu.elte.refjava.lang.refJava.PMemberFeatureCall
import hu.elte.refjava.lang.refJava.PMetaVariable
import hu.elte.refjava.lang.refJava.PMethodDeclaration
import hu.elte.refjava.lang.refJava.PNothingExpression
import hu.elte.refjava.lang.refJava.PTargetExpression
import hu.elte.refjava.lang.refJava.PVariableDeclaration
import hu.elte.refjava.lang.refJava.Pattern
import hu.elte.refjava.lang.refJava.Visibility
import java.util.List
import java.util.Map
import java.util.Queue
import org.eclipse.jdt.core.dom.AST
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.Block
import org.eclipse.jdt.core.dom.Expression
import org.eclipse.jdt.core.dom.MethodDeclaration
import org.eclipse.jdt.core.dom.Modifier.ModifierKeyword
import org.eclipse.jdt.core.dom.SingleVariableDeclaration
import org.eclipse.jdt.core.dom.Type
import org.eclipse.jdt.core.dom.rewrite.ASTRewrite
import hu.elte.refjava.lang.refJava.PReturnExpression

class ASTBuilder {

	Pattern pattern
	AST ast
	ASTRewrite rewrite
	Map<String, List<? extends ASTNode>> bindings
	Map<String, String> nameBindings
	Map<String, Type> typeBindings
	Map<String, List<SingleVariableDeclaration>> parameterBindings
	Map<String, Visibility> visibilityBindings
	Map<String, List<Expression>> argumentBindings
	Queue<String> typeReferenceQueue
	
	new(Pattern pattern) {
		this.pattern = pattern
	}

	def getRewrite() {
		rewrite
	}
	
	def build(Pattern pattern, AST ast, Map<String, List<? extends ASTNode>> bindings, Map<String, String> nameBindings, Map<String, Type> typeBindings, Map<String, List<SingleVariableDeclaration>> parameterBindings, Map<String, Visibility> visibilityBindings, Map<String, List<Expression>> argumentBindings, String typeRefString) {
		this.pattern = pattern
		build(ast, bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
	}
	
	def build(AST ast, Map<String, List<? extends ASTNode>> bindings, Map<String, String> nameBindings, Map<String, Type> typeBindings, Map<String, List<SingleVariableDeclaration>> parameterBindings, Map<String, Visibility> visibilityBindings, Map<String, List<Expression>> argumentBindings, String typeRefString) {
		this.ast = ast
		this.rewrite = ASTRewrite.create(ast)
		this.bindings = bindings
		this.nameBindings = nameBindings
		this.typeBindings = typeBindings
		this.parameterBindings = parameterBindings
		this.visibilityBindings = visibilityBindings
		this.argumentBindings = argumentBindings
		
		if(typeRefString !== null) {
			val tmp = typeRefString.split("\\|")
			this.typeReferenceQueue = newLinkedList
			this.typeReferenceQueue.addAll(tmp)
		}
		
		if(pattern.patterns.head instanceof PNothingExpression) {
			val List<ASTNode> emptyList = newArrayList
			emptyList
		} else {
			pattern.patterns.doBuildPatterns
		}
	}
	
	def buildNewInterface(PMemberFeatureCall lambdaExpr, AST ast, Map<String, List<? extends ASTNode>> bindings, Map<String, String> nameBindings, Map<String, Type> typeBindings, Map<String, List<SingleVariableDeclaration>> parameterBindings, Map<String, Visibility> visibilityBindings, Map<String, List<Expression>> argumentBindings, String typeRefString){
		this.ast = ast
		this.bindings = bindings
		this.nameBindings = nameBindings
		this.typeBindings = typeBindings
		this.parameterBindings = parameterBindings
		this.visibilityBindings = visibilityBindings
		this.argumentBindings = argumentBindings
		
		val newInterface = ast.newTypeDeclaration
		newInterface.interface = true
		
		if((lambdaExpr.memberCallTarget as PConstructorCall).metaName !== null) {
			val name = ((lambdaExpr.memberCallTarget as PConstructorCall).metaName as PMetaVariable).name
			if (nameBindings.get(name) === null) {
				newInterface.name.identifier = Check.generateNewName()
			} else {
				newInterface.name.identifier = nameBindings.get(name)
			}
		} else {
			newInterface.name.identifier = (lambdaExpr.memberCallTarget as PConstructorCall).name
		}
		
		if(typeRefString !== null) {
			val tmp = typeRefString.split("\\|")
			this.typeReferenceQueue = newLinkedList
			this.typeReferenceQueue.addAll(tmp)
		}
		
		val lambdaExpressionBody = (lambdaExpr.memberCallTarget as PConstructorCall).elements
		val newInterfaceBodyDeclarations = lambdaExpressionBody.doBuildPatterns
		
		newInterfaceBodyDeclarations.forEach[
			if(it instanceof MethodDeclaration) {
				it.body = null
			}
		]
		
		newInterface.bodyDeclarations.addAll(newInterfaceBodyDeclarations.filter[it instanceof MethodDeclaration])
		newInterface
	}
	
	///////////////////////
	// doBuild overloads //
	///////////////////////
	def private dispatch doBuild(PMetaVariable metaVar) {
		val binding = bindings.get(metaVar.name)
		if (!binding.empty) {
			val copies = binding.map[ASTNode.copySubtree(ast, it)]
			rewrite.createGroupNode(copies)
		}
	}
	
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
			val name = (constCall.metaName as PMetaVariable).name
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
		
		class
	}
	
	//method declaration builder
	def private dispatch ASTNode doBuild(PMethodDeclaration methodDecl) {
		val method = ast.newMethodDeclaration
		
		//adding method name
		if (methodDecl.prefix.metaName !== null) {
			val name = (methodDecl.prefix.metaName as PMetaVariable).name
			method.name.identifier = nameBindings.get(name)
		} else {
			method.name.identifier = methodDecl.prefix.name
		}
		
		//adding method visibility
		if (methodDecl.prefix.metaVisibility !== null) {
			val metaVarName = (methodDecl.prefix.metaVisibility as PMetaVariable).name
			switch visibilityBindings.get(metaVarName) {
				case PUBLIC: method.modifiers().add(ast.newModifier(ModifierKeyword.PUBLIC_KEYWORD))
				case PRIVATE: method.modifiers().add(ast.newModifier(ModifierKeyword.PRIVATE_KEYWORD))
				case PROTECTED: method.modifiers().add(ast.newModifier(ModifierKeyword.PROTECTED_KEYWORD))
				default: {}
			}
		} else {
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
			val name = (methodDecl.prefix.metaType as PMetaVariable).name
			method.returnType2 = ASTNode.copySubtree(ast, typeBindings.get(name)) as Type
		}
		
		//adding method parameters
		if (methodDecl.parameters.size > 0) {
			for(argument : methodDecl.parameters) {
				val typeName = typeReferenceQueue.remove
				val methodParameterDeclaration = ast.newSingleVariableDeclaration
				methodParameterDeclaration.type = Utils.getTypeFromId(typeName, ast)
				methodParameterDeclaration.name.identifier = argument.name
				method.parameters.add(methodParameterDeclaration)
			}
		} else if (methodDecl.metaParameters !== null) {
			val parameterList = parameterBindings.get((methodDecl.metaParameters as PMetaVariable).name)
			method.parameters.addAll(ASTNode.copySubtrees(ast, parameterList))
		}
		
		//adding method body
		val block = ast.newBlock
		val methodBody = (methodDecl.body as PBlockExpression).expressions
		var List<ASTNode> methodBodyList = newArrayList
		for(element : methodBody) {
			if(element instanceof PMetaVariable) {
				val binding = bindings.get((element as PMetaVariable).name)
				val copies = binding.map[ASTNode.copySubtree(ast, it)]
				methodBodyList.addAll(copies)
			} else if (element instanceof PTargetExpression) {
				val binding = bindings.get("target")
				val copies = binding.map[ASTNode.copySubtree(ast, it)]
				methodBodyList.addAll(copies)
			} else if (element instanceof PVariableDeclaration) {
				methodBodyList.add(element.doBuildVariableDeclarationStatement)
			} else {
				methodBodyList.add(element.doBuild)
			}
		}
		
		if (methodBodyList.size == 1 && methodBodyList.head instanceof Block) {
			method.body = (methodBodyList.head as Block)
		} else {
			block.statements.addAll(methodBodyList)
			method.body = block
		}
		method
	}
	
	//variable declaration builder
	def private doBuildVariableDeclarationStatement(PVariableDeclaration varDecl) {
		val fragment = ast.newVariableDeclarationFragment
		
		//adding variable name
		if(varDecl.metaName !== null) {
			fragment.name.identifier = nameBindings.get((varDecl.metaName as PMetaVariable).name)
		} else {
			fragment.name.identifier = varDecl.name
		}
		
		val newVar = ast.newVariableDeclarationStatement(fragment)
		
		//adding variable type
		if(varDecl.type !== null) {
			newVar.type = Utils.getTypeFromId(typeReferenceQueue.remove, ast)
		} else {
			val name = (varDecl.metaType as PMetaVariable).name
			newVar.type = ASTNode.copySubtree(ast, typeBindings.get(name) as ASTNode) as Type
		}
		newVar
	}
	
	
	//field declaration builder
	def private dispatch doBuild(PVariableDeclaration varDecl) {
		val fragment = ast.newVariableDeclarationFragment
		
		//adding field name
		if(varDecl.metaName !== null) {
			fragment.name.identifier = nameBindings.get( (varDecl.metaName as PMetaVariable).name )
		} else {
			fragment.name.identifier = varDecl.name
		}
		
		val newField = ast.newFieldDeclaration(fragment)
		
		//adding field visibility
		if (varDecl.metaVisibility !== null) {
			val metaVarName = (varDecl.metaVisibility as PMetaVariable).name
			switch visibilityBindings.get(metaVarName) {
				case PUBLIC: newField.modifiers().add(ast.newModifier(ModifierKeyword.PUBLIC_KEYWORD))
				case PRIVATE: newField.modifiers().add(ast.newModifier(ModifierKeyword.PRIVATE_KEYWORD))
				case PROTECTED: newField.modifiers().add(ast.newModifier(ModifierKeyword.PROTECTED_KEYWORD))
				default: {}
			}
		} else {
			switch varDecl.visibility {
				case PUBLIC: newField.modifiers().add(ast.newModifier(ModifierKeyword.PUBLIC_KEYWORD))
				case PRIVATE: newField.modifiers().add(ast.newModifier(ModifierKeyword.PRIVATE_KEYWORD))
				case PROTECTED: newField.modifiers().add(ast.newModifier(ModifierKeyword.PROTECTED_KEYWORD))
				default: {}
			}
		}
		
		//adding field type
		if(varDecl.type !== null) {
			newField.type = Utils.getTypeFromId(typeReferenceQueue.remove, ast)
		} else {
			val name = (varDecl.metaType as PMetaVariable).name
			newField.type = ASTNode.copySubtree(ast, typeBindings.get(name)) as Type
		}
		
		newField
	}
	
	//method invocation (with expression) builder
	def private dispatch ASTNode doBuild(PMemberFeatureCall featureCall) {
		val methodInv = ast.newMethodInvocation
		
		//adding method invocation name
		if (featureCall.feature !== null) {
			methodInv.name.identifier = featureCall.feature
		} else {
			val name = (featureCall.metaFeature as PMetaVariable).name
			methodInv.name.identifier = nameBindings.get(name)
		}
		
		//adding method invocation arguments
		if(featureCall.memberCallArguments !== null) {
			val argumentList = argumentBindings.get((featureCall.memberCallArguments as PMetaVariable).name)
			for (argument : argumentList) {
				val expression = ASTNode.copySubtree(ast, argument)
				methodInv.arguments.add(expression)
			}
		}
		
		//adding method invocation expression
		val buildInvocationExpression = featureCall.memberCallTarget.doBuild
		methodInv.expression = buildInvocationExpression as Expression
		
		val statement = ast.newExpressionStatement(methodInv)
		statement
	}
	
	//method invocation (without expression) builder
	def private dispatch doBuild(PFeatureCall featureCall) {
		val methodInv = ast.newMethodInvocation
		
		//adding method invocation name
		methodInv.name.identifier = featureCall.feature
		
		//adding method arguments
		if(featureCall.featureCallArguments !== null) {
			val argumentList = argumentBindings.get((featureCall.featureCallArguments as PMetaVariable).name)
			for (argument : argumentList) {
				val expression = ASTNode.copySubtree(ast, argument)
				methodInv.arguments.add(expression)
			}
		}
		
		val statement = ast.newExpressionStatement(methodInv)
		statement
	}
	
	//return statement builder
	def private dispatch ASTNode doBuild(PReturnExpression returnExpr) {
		val returnStatement = ast.newReturnStatement
		
		if(returnExpr.expression !== null && returnExpr.expression instanceof PMetaVariable) {
			val expression = bindings.get((returnExpr.expression as PMetaVariable).name)
			println(expression.head.class)
			if (expression.head instanceof Expression) {
				val copy = ASTNode.copySubtree(ast, expression.head) as Expression
				returnStatement.expression = copy
			}
		}
		returnStatement
	}
	
	//block builder
	def private dispatch doBuild(PBlockExpression blockPattern) {
		val block = ast.newBlock
		val builtStatements = blockPattern.expressions.doBuildPatterns
		block.statements.addAll(builtStatements)
		block
	}
	
	def private List<ASTNode> doBuildPatterns(List<PExpression> patterns) {
		patterns.map[doBuild].filterNull.toList
	}
}
