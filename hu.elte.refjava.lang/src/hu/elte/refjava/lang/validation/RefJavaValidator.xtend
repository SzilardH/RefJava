package hu.elte.refjava.lang.validation

import hu.elte.refjava.lang.refJava.MetaVariable
import hu.elte.refjava.lang.refJava.PMetaVariable
import hu.elte.refjava.lang.refJava.RefJavaPackage
import hu.elte.refjava.lang.refJava.SchemeInstanceRule
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.validation.Check

import static hu.elte.refjava.lang.refJava.RefJavaPackage.Literals.*

class RefJavaValidator extends AbstractRefJavaValidator {

	@Check
	def checkMetaVariableUniqueness(SchemeInstanceRule schemeInstanceRule) {
		val matchingMetaVars = EcoreUtil2.getAllContentsOfType(schemeInstanceRule.matchingPattern, PMetaVariable)
		matchingMetaVars.forEach [ inspectedMetaVar |
			if (matchingMetaVars.exists[name == inspectedMetaVar.name && it != inspectedMetaVar]) {
				error("Duplicate metavariable " + inspectedMetaVar.name, inspectedMetaVar,
					RefJavaPackage.Literals.PMETA_VARIABLE__NAME)
			}
		]
	}

	@Check
	def checkMetaVariableReferences(SchemeInstanceRule schemeInstanceRule) {
		val matchingMetaVars = EcoreUtil2.getAllContentsOfType(schemeInstanceRule.matchingPattern, PMetaVariable)
		val metaVarChecker = [ EObject inspectedMetaVar, String inspectedName, boolean inspectedMulti,
				EAttribute nameFeature, EAttribute multiFeature |
			val referencedMetaVar = matchingMetaVars.findFirst[name == inspectedName]
			if (referencedMetaVar === null) {
				error("Metavariable " + inspectedName + " cannot be resolved", inspectedMetaVar, nameFeature)
			} else if (inspectedMulti != referencedMetaVar.multi) {
				error("Metavariable " + inspectedName + " has wrong multiplicity", inspectedMetaVar, multiFeature)
			}
		]

		EcoreUtil2.getAllContentsOfType(schemeInstanceRule.replacementPattern, PMetaVariable).forEach [
			metaVarChecker.apply(it, name, multi, PMETA_VARIABLE__NAME, PMETA_VARIABLE__MULTI)
		]
		EcoreUtil2.getAllContentsOfType(schemeInstanceRule.precondition, MetaVariable).forEach [
			metaVarChecker.apply(it, name, multi, META_VARIABLE__NAME, META_VARIABLE__MULTI)
		]
	}

}
