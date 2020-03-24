package hu.elte.refjava.lang.compiler

import hu.elte.refjava.lang.refJava.MetaVariable
import hu.elte.refjava.lang.refJava.NameMetaVariable
import hu.elte.refjava.lang.refJava.ParameterMetaVariable
import hu.elte.refjava.lang.refJava.TargetExpression
import hu.elte.refjava.lang.refJava.TypeMetaVariable
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
			NameMetaVariable:
				expression.toJavaStatement(builder)
			TypeMetaVariable:
				expression.toJavaStatement(builder)
			ParameterMetaVariable:
				expression.toJavaStatement(builder)
			default:
				super.doInternalToJavaStatement(expression, builder, isReferenced)
		}
	}

	def void toJavaStatement(MetaVariable metaVar, ITreeAppendable it) {
		// do nothing, a metavariable is strictly an expression
	}
	
	def void toJavaStatement(NameMetaVariable metaVar, ITreeAppendable it) {
		// do nothing, a metavariable is strictly an expression
	}
	
	def void toJavaStatement(TypeMetaVariable metaVar, ITreeAppendable it) {
		// do nothing, a metavariable is strictly an expression
	}
	
	def void toJavaStatement(ParameterMetaVariable metaVar, ITreeAppendable it) {
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
			NameMetaVariable:
				expression.toJavaExpression(builder)
			TypeMetaVariable:
				expression.toJavaExpression(builder)
			ParameterMetaVariable:
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
	
	def dispatch void toJavaExpression(NameMetaVariable metaVar, ITreeAppendable it) {
		append('''nameBindings.get("«metaVar.name»")''')
	}
	
	def dispatch void toJavaExpression(TypeMetaVariable metaVar, ITreeAppendable it) {
		append('''typeBindings.get("«metaVar.name»")''')
	}
	
	def dispatch void toJavaExpression(ParameterMetaVariable metaVar, ITreeAppendable it) {
		append('''parameterBindings.get("«metaVar.name»")''')
	}
	
	def dispatch void toJavaExpression(TargetExpression targetExpr, ITreeAppendable it) {
		append('''bindings.get("target")''')
	}
}
