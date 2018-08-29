package hu.elte.refjava.lang.typesystem

import hu.elte.refjava.lang.refJava.MetaVariable
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

}
