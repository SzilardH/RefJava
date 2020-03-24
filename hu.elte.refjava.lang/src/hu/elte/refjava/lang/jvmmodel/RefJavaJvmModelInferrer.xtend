package hu.elte.refjava.lang.jvmmodel

import com.google.inject.Inject
import hu.elte.refjava.api.BlockRefactoring
import hu.elte.refjava.api.ClassRefactoring
import hu.elte.refjava.api.LambdaRefactoring
import hu.elte.refjava.api.LocalRefactoring
import hu.elte.refjava.lang.refJava.PMethodDeclaration
import hu.elte.refjava.lang.refJava.PNameMetaVariable
import hu.elte.refjava.lang.refJava.PParameterMetaVariable
import hu.elte.refjava.lang.refJava.PTypeMetaVariable
import hu.elte.refjava.lang.refJava.SchemeInstanceRule
import hu.elte.refjava.lang.refJava.SchemeType
import java.lang.reflect.Type
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.common.types.JvmVisibility
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.serializer.ISerializer
import org.eclipse.xtext.xbase.jvmmodel.AbstractModelInferrer
import org.eclipse.xtext.xbase.jvmmodel.IJvmDeclaredTypeAcceptor
import org.eclipse.xtext.xbase.jvmmodel.JvmTypesBuilder
import java.util.List

class RefJavaJvmModelInferrer extends AbstractModelInferrer {

	@Inject extension IQualifiedNameProvider
	@Inject extension ISerializer
	@Inject extension JvmTypesBuilder
	

	def dispatch infer(SchemeInstanceRule rule, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		acceptor.accept(rule.toClass(rule.fullyQualifiedName)) [
			superTypes += rule.type.toSuperType.typeRef
			
			
			//type parsing doesn't work..
			var String typeReferenceString = ""
			val methodDeclarations = EcoreUtil2.getAllContentsOfType(rule.replacementPattern, PMethodDeclaration)
			for(method : methodDeclarations) {
				if(method.prefix.type !== null) {
					typeReferenceString = typeReferenceString + method.prefix.type.identifier + "|"
				}
				for (args : method.arguments) {
					if(args.parameterType.type !== null) {
						typeReferenceString = typeReferenceString + args.parameterType.identifier + "|"
					}
				}
			}
			
			members += rule.toConstructor [
				body = '''super("«rule.matchingPattern.serialize.trim»", "«rule.replacementPattern.serialize.trim»");'''
			]
			
			val endl = System.getProperty("line.separator");
			var String callings = ""
			if(rule.assignment !== null) {
 				for (assignment : rule.assignment.assignment) {
					if (assignment.name instanceof PNameMetaVariable) {
						val name = (assignment.name as PNameMetaVariable).name
						members += rule.toMethod("valueof_name_" + name, typeof(String).typeRef) [
							visibility = JvmVisibility.PRIVATE
							body = assignment.value
						]
						callings = callings + "set_name_" + name + "();" + endl
						members += rule.toMethod("set_name_" + name, typeof(void).typeRef) [
							visibility = JvmVisibility.PRIVATE
							body = '''nameBindings.put("«name»", valueof_name_«name»());'''
						]
					} else if (assignment.name instanceof PTypeMetaVariable) {
						val name = (assignment.name as PTypeMetaVariable).name
						members += rule.toMethod("valueof_type_" + name, typeof(Type).typeRef) [
							visibility = JvmVisibility.PRIVATE
							body = assignment.value
						]
						callings = callings + "set_type_" + name + "();" + endl
						members += rule.toMethod("set_type_" + name, typeof(void).typeRef) [
							visibility = JvmVisibility.PRIVATE
							body = '''typeBindings.put("«name»", valueof_type_«name»());'''
						]
					} else if (assignment.name instanceof PParameterMetaVariable) {
						val name = (assignment.name as PParameterMetaVariable).name
						members += rule.toMethod("valueof_parameter_" + name, typeof(List).typeRef) [
							visibility = JvmVisibility.PRIVATE
							body = assignment.value
						]
						callings = callings + "set_parameter_" + name + "();" + endl
						members += rule.toMethod("set_parameter_" + name, typeof(void).typeRef) [
							visibility = JvmVisibility.PRIVATE
							body = '''parameterBindings.put("«name»", valueof_parameter_«name»());'''
						]
					}
				}
			}
			
			val finalTypesReferenceString = typeReferenceString
			val finalCallings = callings + endl
			if (finalTypesReferenceString.length > 0) {
				members += rule.toMethod("setMetaVariables", typeof(void).typeRef) [
					annotations += annotationRef(Override)
					visibility = JvmVisibility.PROTECTED
					body = '''«finalCallings»super.typeReferenceString = "«finalTypesReferenceString»";'''
				]
			}
			
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
			
			if (rule.targetPattern !== null) {
				members += rule.toMethod("safeTargetCheck", Boolean.TYPE.typeRef) [
					annotations += annotationRef(Override)
					visibility = JvmVisibility.PROTECTED
					body = '''return super.targetCheck("«rule.targetPattern.serialize.trim»");'''
				]
			}
		]
	}

	def private toSuperType(SchemeType it) {
		switch it {
			case LOCAL : return LocalRefactoring
			case BLOCK : return BlockRefactoring
			case LAMBDA : return LambdaRefactoring
			case CLASS : return ClassRefactoring
		}
	}

}
