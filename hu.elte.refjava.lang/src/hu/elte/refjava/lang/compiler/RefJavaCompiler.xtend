package hu.elte.refjava.lang.compiler

import hu.elte.refjava.lang.refJava.MetaVariable
import org.eclipse.xtext.xbase.XExpression
import org.eclipse.xtext.xbase.compiler.XbaseCompiler
import org.eclipse.xtext.xbase.compiler.output.ITreeAppendable

class RefJavaCompiler extends XbaseCompiler {

	override protected doInternalToJavaStatement(XExpression expression, ITreeAppendable builder, boolean isReferenced) {
		switch expression {
			MetaVariable:
				expression.toJavaStatement(builder)
			default:
				super.doInternalToJavaStatement(expression, builder, isReferenced)
		}
	}

	def void toJavaStatement(MetaVariable metaVar, ITreeAppendable it) {
		// do nothing, a metavariable is strictly an expression
	}

	override protected internalToConvertedExpression(XExpression expression, ITreeAppendable builder) {
		switch expression {
			MetaVariable:
				expression.toJavaExpression(builder)
			default:
				super.internalToConvertedExpression(expression, builder)
		}
	}

	def dispatch void toJavaExpression(MetaVariable metaVar, ITreeAppendable it) {
		append('''bindings.get("«metaVar.name»")''')
		if (!metaVar.multi) {
			append(".get(0)")
		}
	}

}
