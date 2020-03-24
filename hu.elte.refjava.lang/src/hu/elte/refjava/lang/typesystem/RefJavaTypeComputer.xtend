package hu.elte.refjava.lang.typesystem

import hu.elte.refjava.lang.refJava.MetaVariable
import hu.elte.refjava.lang.refJava.NameMetaVariable
import hu.elte.refjava.lang.refJava.ParameterMetaVariable
import hu.elte.refjava.lang.refJava.TargetExpression
import hu.elte.refjava.lang.refJava.TypeMetaVariable
import java.lang.reflect.Type
import java.util.List
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.xtext.xbase.typesystem.computation.ITypeComputationState
import org.eclipse.xtext.xbase.typesystem.computation.XbaseTypeComputer
import org.eclipse.xtext.xbase.typesystem.references.ParameterizedTypeReference

class RefJavaTypeComputer extends XbaseTypeComputer {

	def dispatch computeTypes(MetaVariable metaVar, ITypeComputationState state) {
		val astNodeType = getTypeForName(ASTNode, state)

		val type = if (!metaVar.multi) {
			astNodeType
		} else {
			val listType = getTypeForName(List, state) as ParameterizedTypeReference
			listType.addTypeArgument(astNodeType)
			listType
		}

		state.acceptActualType(type)
	}
	
	def dispatch computeTypes(NameMetaVariable metaVar, ITypeComputationState state) {
		val stringType = getTypeForName(String, state)
		state.acceptActualType(stringType)
	}
	
	def dispatch computeTypes(TypeMetaVariable metaVar, ITypeComputationState state) {
		val typeType = getTypeForName(Type, state)
		state.acceptActualType(typeType)
	}
	
	def dispatch computeTypes(ParameterMetaVariable metaVar, ITypeComputationState state) {
		val pairType = getTypeForName(Pair, state) as ParameterizedTypeReference
		val typeType = getTypeForName(Type, state)
		val stringType = getTypeForName(String, state)
		pairType.addTypeArgument(typeType)
		pairType.addTypeArgument(stringType)
		
		val type = if(!metaVar.multi) {
			pairType
		} else {
			val listType = getTypeForName(List, state) as ParameterizedTypeReference
			listType.addTypeArgument(pairType)
			listType
		}
		state.acceptActualType(type)
	}

	def dispatch computeTypes(TargetExpression targetExpr, ITypeComputationState state) {
		val astNodeType = getTypeForName(ASTNode, state)
		state.acceptActualType(astNodeType)
	}
	
	
}
