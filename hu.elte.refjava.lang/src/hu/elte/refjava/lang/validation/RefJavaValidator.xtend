package hu.elte.refjava.lang.validation

import hu.elte.refjava.lang.refJava.MetaVariable
import hu.elte.refjava.lang.refJava.PBlockExpression
import hu.elte.refjava.lang.refJava.PExpression
import hu.elte.refjava.lang.refJava.PMetaVariable
import hu.elte.refjava.lang.refJava.PTargetExpression
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
	
	@Check
	def multiMetavariableCountValidation(SchemeInstanceRule schemeInstanceRule) {
		val patterns = schemeInstanceRule.matchingPattern.patterns
		val targetExpressions = EcoreUtil2.getAllContentsOfType(schemeInstanceRule.matchingPattern, PTargetExpression)
		if(targetExpressions.size != 0) {
			
			if (targetExpressions.size > 1) {
				targetExpressions.forEach[error("Two or more target expression within the same matching pattern doesn't make sense.", it, RefJavaPackage.Literals.PTARGET_EXPRESSION.getEStructuralFeature(0) )]
			}
			val preTargetExpressions = patterns.clone.takeWhile[ !(it instanceof PTargetExpression)]
			val postTargetExpressions = patterns.clone.reverse.takeWhile[ !(it instanceof PTargetExpression)]
			
			multiMetavarCountChecker(preTargetExpressions)
			multiMetavarCountChecker(postTargetExpressions)
			
		} else {
			multiMetavarCountChecker(patterns)
		}
	}
	
	def void multiMetavarCountChecker(Iterable<PExpression> expressions) {
		val multiMetavars = expressions.filter[it instanceof PMetaVariable && (it as PMetaVariable).multi]
		val blocks = expressions.filter[it instanceof PBlockExpression]
		
		if (multiMetavars.size > 1) {
			multiMetavars.forEach[error("Two or more metavariable with multiplicity in the same scope doesn't make sense.
If the matching pattern has a target expression, then there cannot be two or more
metavariable with multiplicity before, and after the target expression.", it, RefJavaPackage.Literals.PMETA_VARIABLE__MULTI)]
		}
		
		blocks.forEach[multiMetavarCountChecker( (it as PBlockExpression).expressions )]
		
	}

}
