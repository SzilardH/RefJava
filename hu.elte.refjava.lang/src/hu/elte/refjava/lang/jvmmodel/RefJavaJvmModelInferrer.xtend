package hu.elte.refjava.lang.jvmmodel

import com.google.inject.Inject
import hu.elte.refjava.api.LocalRefactoring
import hu.elte.refjava.lang.refJava.SchemeInstanceRule
import hu.elte.refjava.lang.refJava.SchemeType
import org.eclipse.xtext.common.types.JvmVisibility
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.serializer.ISerializer
import org.eclipse.xtext.xbase.jvmmodel.AbstractModelInferrer
import org.eclipse.xtext.xbase.jvmmodel.IJvmDeclaredTypeAcceptor
import org.eclipse.xtext.xbase.jvmmodel.JvmTypesBuilder

class RefJavaJvmModelInferrer extends AbstractModelInferrer {

	@Inject extension IQualifiedNameProvider
	@Inject extension ISerializer
	@Inject extension JvmTypesBuilder

	def dispatch infer(SchemeInstanceRule rule, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		acceptor.accept(rule.toClass(rule.fullyQualifiedName)) [
			superTypes += rule.type.toSuperType.typeRef

			members += rule.toConstructor [
				body = '''super("«rule.matchingPattern.serialize.trim»", "«rule.replacementPattern.serialize.trim»");'''
			]

			if (rule.precondition !== null) {
				members += rule.toMethod("instanceCheck", Boolean.TYPE.typeRef) [
					visibility = JvmVisibility.PRIVATE
					body = rule.precondition
				]

				members += rule.toMethod("check", Boolean.TYPE.typeRef) [
					annotations += annotationRef(Override)
					visibility = JvmVisibility.PROTECTED
					body = '''return super.check() && instanceCheck();'''
				]
			}
		]
	}

	def private toSuperType(SchemeType it) {
		LocalRefactoring
	}

}
