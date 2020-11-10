package hu.elte.refjava.lang.compiler

import hu.elte.refjava.lang.refJava.MetaVariable
import hu.elte.refjava.lang.refJava.MetaVariableType
import hu.elte.refjava.lang.refJava.TargetExpression
import org.eclipse.xtext.xbase.XExpression
import org.eclipse.xtext.xbase.compiler.XbaseCompiler
import org.eclipse.xtext.xbase.compiler.output.ITreeAppendable

class RefJavaCompiler extends XbaseCompiler {

	override protected doInternalToJavaStatement(XExpression expression, ITreeAppendable builder, boolean isReferenced) {
		switch expression {
			MetaVariable:
				expression.toJavaStatement(builder)
			TargetExpression:
				expression.toJavaStatement(builder)
			default:
				super.doInternalToJavaStatement(expression, builder, isReferenced)
		}
	}

	def void toJavaStatement(MetaVariable metaVar, ITreeAppendable it) {
		// do nothing, a metavariable is strictly an expression
	}
	
	def void toJavaStatement(TargetExpression targetExpr, ITreeAppendable it) {
		// do nothing, a metavariable is strictly an expression
	}

	override protected internalToConvertedExpression(XExpression expression, ITreeAppendable builder) {
		switch expression {
			MetaVariable:
				expression.toJavaExpression(builder)
			TargetExpression:
				expression.toJavaExpression(builder)
			default:
				super.internalToConvertedExpression(expression, builder)
		}
	}

	def dispatch void toJavaExpression(MetaVariable metaVar, ITreeAppendable it) {
		if(metaVar.type == MetaVariableType.CODE) {
			append('''bindings.get("«metaVar.name»")''')
			if (!metaVar.multi) {
				append(".get(0)")
			}
		} else if (metaVar.type == MetaVariableType.NAME) {
			append('''nameBindings.get("«metaVar.name»")''')
		} else if (metaVar.type == MetaVariableType.TYPE) {
			append('''typeBindings.get("«metaVar.name»")''')
		} else if (metaVar.type == MetaVariableType.PARAMETER) {
			append('''parameterBindings.get("«metaVar.name»")''')
		} else if (metaVar.type == MetaVariableType.VISIBILITY) {
			append('''visibilityBindings.get("«metaVar.name»")''')
		}
	}
	
	def dispatch void toJavaExpression(TargetExpression targetExpr, ITreeAppendable it) {
		append('''bindings.get("target")''')
	}
}
