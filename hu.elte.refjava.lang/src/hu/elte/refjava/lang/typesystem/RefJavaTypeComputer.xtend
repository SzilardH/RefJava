package hu.elte.refjava.lang.typesystem

import hu.elte.refjava.lang.refJava.MetaVariable
import hu.elte.refjava.lang.refJava.MetaVariableType
import hu.elte.refjava.lang.refJava.TargetExpression
import java.util.List
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.Expression
import org.eclipse.jdt.core.dom.SingleVariableDeclaration
import org.eclipse.jdt.core.dom.Type
import org.eclipse.xtext.xbase.typesystem.computation.ITypeComputationState
import org.eclipse.xtext.xbase.typesystem.computation.XbaseTypeComputer
import org.eclipse.xtext.xbase.typesystem.references.ParameterizedTypeReference

class RefJavaTypeComputer extends XbaseTypeComputer {

	def dispatch computeTypes(MetaVariable metaVar, ITypeComputationState state) {
		if (metaVar.type == MetaVariableType.CODE) {
			val astNodeType = getTypeForName(ASTNode, state)
			val type = if (!metaVar.multi) {
				astNodeType
			} else {
				val listType = getTypeForName(List, state) as ParameterizedTypeReference
				listType.addTypeArgument(astNodeType)
				listType
			}
			state.acceptActualType(type)
			
		} else if (metaVar.type == MetaVariableType.NAME) {
			val stringType = getTypeForName(String, state)
			state.acceptActualType(stringType)
			
		} else if (metaVar.type == MetaVariableType.TYPE) {
			val typeType = getTypeForName(Type, state)
			state.acceptActualType(typeType)
			
		} else if (metaVar.type == MetaVariableType.PARAMETER) {
			val parameterType = getTypeForName(SingleVariableDeclaration, state)
			val listType = getTypeForName(List, state) as ParameterizedTypeReference
			listType.addTypeArgument(parameterType)
			state.acceptActualType(listType)
			
		} else if(metaVar.type == MetaVariableType.ARGUMENT) {
			val expressionType = getTypeForName(Expression, state)
			val listType = getTypeForName(List, state) as ParameterizedTypeReference
			listType.addTypeArgument(expressionType)
			state.acceptActualType(listType)
		}
	}

	def dispatch computeTypes(TargetExpression targetExpr, ITypeComputationState state) {
		val astNodeType = getTypeForName(ASTNode, state)
		val listType = getTypeForName(List, state) as ParameterizedTypeReference
		listType.addTypeArgument(astNodeType)
		val type = listType
		state.acceptActualType(type)
	}
}
