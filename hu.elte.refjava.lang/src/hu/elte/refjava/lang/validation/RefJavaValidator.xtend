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
import hu.elte.refjava.lang.refJava.SchemeType
import hu.elte.refjava.lang.refJava.PNothingExpression
import hu.elte.refjava.lang.refJava.PFeatureCall
import hu.elte.refjava.lang.refJava.PMethodDeclaration
import hu.elte.refjava.lang.refJava.PVariableDeclaration
import hu.elte.refjava.lang.refJava.PMemberFeatureCall
import hu.elte.refjava.lang.refJava.PConstructorCall
import hu.elte.refjava.lang.refJava.MetaVariableType
import hu.elte.refjava.api.patterns.Utils

class RefJavaValidator extends AbstractRefJavaValidator {
	
	@Check
	def checkMetaVariableUniqueness(SchemeInstanceRule schemeInstanceRule) {
		val matchingMetaVars = EcoreUtil2.getAllContentsOfType(schemeInstanceRule.matchingPattern, PMetaVariable)
		matchingMetaVars.forEach [ inspectedMetaVar |
			if (matchingMetaVars.exists[name == inspectedMetaVar.name && type == inspectedMetaVar.type && it != inspectedMetaVar]) {
				error("Duplicate metavariable " + inspectedMetaVar.name, inspectedMetaVar,
					RefJavaPackage.Literals.PMETA_VARIABLE__NAME)
			}
		]
	}
	
	@Check
	def checkMetaVariableReferences(SchemeInstanceRule schemeInstanceRule) {
		val matchingMetaVars = EcoreUtil2.getAllContentsOfType(schemeInstanceRule.matchingPattern, PMetaVariable)
		val metaVarChecker = [ EObject inspectedMetaVar, String inspectedName, MetaVariableType inspectedType, boolean inspectedMulti,
				EAttribute nameFeature, EAttribute multiFeature |
			val referencedMetaVar = matchingMetaVars.findFirst[name == inspectedName]
			if (inspectedType == MetaVariableType.CODE && referencedMetaVar === null) {
				error("Metavariable " + inspectedName + " cannot be resolved", inspectedMetaVar, nameFeature)
			} else if (inspectedType == MetaVariableType.CODE && inspectedMulti != referencedMetaVar.multi) {
				error("Metavariable " + inspectedName + " has wrong multiplicity", inspectedMetaVar, multiFeature)
			}
		]

		EcoreUtil2.getAllContentsOfType(schemeInstanceRule.replacementPattern, PMetaVariable).forEach [
			metaVarChecker.apply(it, name, type, multi, PMETA_VARIABLE__NAME, PMETA_VARIABLE__MULTI)
		]
		EcoreUtil2.getAllContentsOfType(schemeInstanceRule.precondition, MetaVariable).forEach [
			metaVarChecker.apply(it, name, type, multi, META_VARIABLE__NAME, META_VARIABLE__MULTI)
		]
	}
	
	@Check
	def targetPatternChecker(SchemeInstanceRule schemeInstanceRule) {
		if (schemeInstanceRule.type == SchemeType.LOCAL && schemeInstanceRule.targetPattern !== null) {
			
			error("A local refactoring scheme cannot have a target closure.", schemeInstanceRule, SCHEME_INSTANCE_RULE__TYPE)
			
		} else {
			if (schemeInstanceRule.targetPattern !== null) {
				if (EcoreUtil2.getAllContentsOfType(schemeInstanceRule.targetPattern, PTargetExpression) !== null) {
					EcoreUtil2.getAllContentsOfType(schemeInstanceRule.targetPattern, PTargetExpression).forEach[
						error("The target pattern cannot contain a target expression.", it, PTARGET_EXPRESSION.getEStructuralFeature(0))
					]
				}
			}
		}
	}
	
	//checks the attribute-binding meta variable type correctness
	@Check
	def metaVariableTypeCorrectnessChecker(SchemeInstanceRule schemeInstanceRule) {
		schemeInstanceRule.matchingPattern.patterns.forEach[hasCorrectMetaVariableTypes]
		schemeInstanceRule.replacementPattern.patterns.forEach[hasCorrectMetaVariableTypes]
		schemeInstanceRule.targetPattern.patterns.forEach[hasCorrectMetaVariableTypes]
		schemeInstanceRule.definitionPattern.patterns.forEach[hasCorrectMetaVariableTypes]
	}
	
	def void hasCorrectMetaVariableTypes(PExpression expression) {
		if (expression instanceof PMethodDeclaration) {
			val method = expression as PMethodDeclaration
			if (method.metaParameters !== null && (method.metaParameters as PMetaVariable).type != MetaVariableType.PARAMETER) {
				error("The type of the meta variable should be 'parameter' here.", method.metaParameters, PMETA_VARIABLE__TYPE)
			}
			method.prefix.hasCorrectMetaVariableTypes
		} else if (expression instanceof PVariableDeclaration) {
			val varDecl = expression as PVariableDeclaration
			if(varDecl.metaName !== null && (varDecl.metaName as PMetaVariable).type != MetaVariableType.NAME) {
				error("The type of the meta variable should be 'name' here.", varDecl.metaName, PMETA_VARIABLE__TYPE)
			}
			if(varDecl.metaType !== null && (varDecl.metaType as PMetaVariable).type != MetaVariableType.TYPE) {
				error("The type of the meta variable should be 'type' here.", varDecl.metaType, PMETA_VARIABLE__TYPE)
			}
			if(varDecl.metaVisibility !== null && (varDecl.metaVisibility as PMetaVariable).type != MetaVariableType.VISIBILITY) {
				error("The type of the meta variable should be 'visibility' here.", varDecl.metaVisibility, PMETA_VARIABLE__TYPE)
			}
		} else if (expression instanceof PMemberFeatureCall) {
			val memberFeatureCall = expression as PMemberFeatureCall
			if(memberFeatureCall.metaFeature !== null && (memberFeatureCall.metaFeature as PMetaVariable).type != MetaVariableType.NAME) {
				error("The type of the meta variable should be 'name' here.", memberFeatureCall.metaFeature, PMETA_VARIABLE__TYPE)
			}
			if(memberFeatureCall.memberCallArguments !== null && (memberFeatureCall.memberCallArguments as PMetaVariable).type != MetaVariableType.ARGUMENT) {
				error("The type of the meta variable should be 'argument' here.", memberFeatureCall.memberCallArguments, PMETA_VARIABLE__TYPE)
			}
			memberFeatureCall.memberCallTarget.hasCorrectMetaVariableTypes
		} else if (expression instanceof PConstructorCall) {
			val constructorCall = expression as PConstructorCall
			if (constructorCall.metaName !== null && (constructorCall.metaName as PMetaVariable).type != MetaVariableType.NAME) {
				error("The type of the meta variable should be 'name' here.", constructorCall.metaName, PMETA_VARIABLE__TYPE)
			}
			if (constructorCall.arguments !== null && (constructorCall.arguments as PMetaVariable).type != MetaVariableType.ARGUMENT) {
				error("The type of the meta variable should be 'argument' here.", constructorCall.arguments, PMETA_VARIABLE__TYPE)
			}
			if (constructorCall.anonInstance) {
				constructorCall.elements.forEach[hasCorrectMetaVariableTypes]
			}
		} else if (expression instanceof PBlockExpression) {
			val block = expression as PBlockExpression
			block.expressions.forEach[hasCorrectMetaVariableTypes]
		} else if (expression instanceof PFeatureCall) {
			val featureCall = expression as PFeatureCall
			if(featureCall.metaFeature !== null && (featureCall.metaFeature as PMetaVariable).type != MetaVariableType.NAME) {
				error("The type of the meta variable should be 'name' here.", featureCall.metaFeature, PMETA_VARIABLE__TYPE)
			}
			if(featureCall.featureCallArguments !== null && (featureCall.featureCallArguments as PMetaVariable).type != MetaVariableType.ARGUMENT) {
				error("The type of the meta variable should be 'argument' here.", featureCall.featureCallArguments, PMETA_VARIABLE__TYPE)
			}
		}
	}
	
	@Check
	def parameterAndArgumentMetaVariableMultiplicity(SchemeInstanceRule schemeInstanceRule) {
		EcoreUtil2.getAllContentsOfType(schemeInstanceRule.matchingPattern, PMetaVariable).forEach[hasCorrectMultiplicity]
		EcoreUtil2.getAllContentsOfType(schemeInstanceRule.replacementPattern, PMetaVariable).forEach[hasCorrectMultiplicity]
		EcoreUtil2.getAllContentsOfType(schemeInstanceRule.targetPattern, PMetaVariable).forEach[hasCorrectMultiplicity]
		EcoreUtil2.getAllContentsOfType(schemeInstanceRule.definitionPattern, PMetaVariable).forEach[hasCorrectMultiplicity]
	}
	
	def hasCorrectMultiplicity(PMetaVariable metaVar) {
		if(metaVar.type == MetaVariableType.PARAMETER && !metaVar.multi) {
			error("A parameter-binding meta variable should always have multiplicity.", metaVar, PMETA_VARIABLE__MULTI)
		} else if (metaVar.type == MetaVariableType.ARGUMENT && !metaVar.multi) {
			error("An argument-binding meta variable should always have multiplicity.", metaVar, PMETA_VARIABLE__MULTI)
		} else if (metaVar.type == MetaVariableType.NAME && metaVar.multi) {
			error("A name-binding meta variable cannot have multiplicity.", metaVar, PMETA_VARIABLE__MULTI)
		} else if (metaVar.type == MetaVariableType.TYPE && metaVar.multi) {
			error("A type-binding meta variable cannot have multiplicity.", metaVar, PMETA_VARIABLE__MULTI)
		} else if (metaVar.type == MetaVariableType.VISIBILITY && metaVar.multi) {
			error("A visibility-binding meta variable cannot have multiplicity.", metaVar, PMETA_VARIABLE__MULTI)
		}
	}
	
	
	//class and lambda refactorings pattern limitations
	@Check
	def patternLimitationsChecker(SchemeInstanceRule schemeInstanceRule) {
		if(schemeInstanceRule.type == SchemeType.CLASS) {
			if (!(schemeInstanceRule.replacementPattern.patterns.head instanceof PNothingExpression) 
				&& !(schemeInstanceRule.replacementPattern.patterns.head instanceof PFeatureCall) 
				|| schemeInstanceRule.replacementPattern.patterns.size > 1) {
					
				error("A class refactoring's replacement pattern can only be either a single nothing expression or a single feature call.", 
					schemeInstanceRule.replacementPattern, PATTERN.getEStructuralFeature(0))
					
			} else if (schemeInstanceRule.replacementPattern.patterns.head instanceof PNothingExpression 
				&& !(schemeInstanceRule.matchingPattern.patterns.head instanceof PMethodDeclaration) 
				&& !(schemeInstanceRule.matchingPattern.patterns.head instanceof PVariableDeclaration)
				|| schemeInstanceRule.matchingPattern.patterns.size > 1) {
				error("The matching pattern can only be either a single method declaration or a single variable declaration, if the replacement pattern is a nothing expression.", 
					schemeInstanceRule.matchingPattern, PATTERN.getEStructuralFeature(0))
			}
		} else if (schemeInstanceRule.type == SchemeType.LAMBDA) {
			
			if (!Utils.isValidLambdaExpression(schemeInstanceRule.replacementPattern.patterns.head) || schemeInstanceRule.replacementPattern.patterns.size > 1) {	
				error("A lambda refactoring's replacement pattern can only be a single valid lambda expression.

Example: new F() { public void apply() { <body> } }.apply()", schemeInstanceRule.replacementPattern, PATTERN.getEStructuralFeature(0))
			
			} else if (schemeInstanceRule.matchingPattern.patterns.exists[Utils.isValidLambdaExpression(it)] && schemeInstanceRule.matchingPattern.patterns.size > 1) {
				
				error("The matching pattern can be either a single lambda expression, or a pattern that doesn't contains a lambda expression.", schemeInstanceRule.replacementPattern, PATTERN.getEStructuralFeature(0))
				
			} else if (!((schemeInstanceRule.replacementPattern.patterns.head as PMemberFeatureCall).memberCallTarget as PConstructorCall).elements.exists[
				it instanceof PMethodDeclaration && ((it as PMethodDeclaration).prefix.name == (schemeInstanceRule.replacementPattern.patterns.head as PMemberFeatureCall).feature 
				&& ((it as PMethodDeclaration).prefix.metaName as PMetaVariable).name == ((schemeInstanceRule.replacementPattern.patterns.head as PMemberFeatureCall).metaFeature as PMetaVariable).name)]) {
				
				error("The feature call's name can only be an existing method inside the lambda expression.", schemeInstanceRule.replacementPattern, PATTERN.getEStructuralFeature(0))
			
			} else if (Utils.isValidLambdaExpression(schemeInstanceRule.matchingPattern.patterns.head) && !((schemeInstanceRule.matchingPattern.patterns.head as PMemberFeatureCall).memberCallTarget as PConstructorCall).elements.exists[
				it instanceof PMethodDeclaration && ((it as PMethodDeclaration).prefix.name == (schemeInstanceRule.matchingPattern.patterns.head as PMemberFeatureCall).feature 
				&& ((it as PMethodDeclaration).prefix.metaName as PMetaVariable).name == ((schemeInstanceRule.matchingPattern.patterns.head as PMemberFeatureCall).metaFeature as PMetaVariable).name)]) {
				
				error("The feature call's name can only be an existing method inside the lambda expression.", schemeInstanceRule.matchingPattern, PATTERN.getEStructuralFeature(0))
			
			} else if (Utils.isValidLambdaExpression(schemeInstanceRule.matchingPattern.patterns.head) && schemeInstanceRule.matchingPattern.patterns.size > 1) {
				error("The matching pattern's length can only be single, if the matching pattern is meant to be a lambda expression.", schemeInstanceRule.matchingPattern, PATTERN.getEStructuralFeature(0))
			}
		}
	}
	
	@Check
	def multiMetavariableCountValidation(SchemeInstanceRule schemeInstanceRule) {
		val matchingPatterns = schemeInstanceRule.matchingPattern.patterns
		val targetExpressions = EcoreUtil2.getAllContentsOfType(schemeInstanceRule.matchingPattern, PTargetExpression)
		if(targetExpressions.size != 0) {
			
			if (targetExpressions.size > 1) {
				targetExpressions.forEach[error("Two or more target expression within the same matching pattern doesn't make sense.", it, PTARGET_EXPRESSION.getEStructuralFeature(0) )]
			}
			val preTargetExpressions = matchingPatterns.clone.takeWhile[ !(it instanceof PTargetExpression)]
			val postTargetExpressions = matchingPatterns.clone.reverse.takeWhile[ !(it instanceof PTargetExpression)]
			multiMetavarCountChecker(preTargetExpressions)
			multiMetavarCountChecker(postTargetExpressions)
			
		} else {
			multiMetavarCountChecker(matchingPatterns)
		}
	}
	
	def void multiMetavarCountChecker(Iterable<PExpression> expressions) {
		val multiMetavars = expressions.filter[it instanceof PMetaVariable && (it as PMetaVariable).multi]
		val blocks = expressions.filter[it instanceof PBlockExpression]
		if (multiMetavars.size > 1) {
			multiMetavars.forEach[error("Two or more metavariable with multiplicity in the same scope doesn't make sense.
If the matching pattern has a target expression, then there cannot be two or more
metavariable with multiplicity before, and after the target expression.", it, PMETA_VARIABLE__MULTI)]
		}
		blocks.forEach[multiMetavarCountChecker( (it as PBlockExpression).expressions )]
	}
}
