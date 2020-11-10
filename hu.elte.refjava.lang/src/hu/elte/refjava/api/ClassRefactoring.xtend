package hu.elte.refjava.api

import hu.elte.refjava.api.patterns.ASTBuilder
import hu.elte.refjava.api.patterns.PatternMatcher
import hu.elte.refjava.api.patterns.PatternParser
import hu.elte.refjava.api.patterns.Utils
import hu.elte.refjava.lang.refJava.PMethodDeclaration
import java.util.List
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.FieldDeclaration
import org.eclipse.jdt.core.dom.MethodDeclaration
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jdt.core.dom.VariableDeclarationFragment
import org.eclipse.jface.text.Document
import org.eclipse.jface.text.IDocument

import static hu.elte.refjava.api.Check.*
import hu.elte.refjava.lang.refJava.Visibility

class ClassRefactoring implements Refactoring {
	
	List<? extends ASTNode> target
	IDocument document
	
	val PatternMatcher matcher
	val ASTBuilder builder
	val String matchingString
	val String replacementString
	val RefactoringType refactoringType
	protected String targetString
	protected String definitionString
	protected String matchingTypeReferenceString
	protected String replacementTypeReferenceString
	protected String targetTypeReferenceString
	protected String definitionTypeReferenceString
	List<ASTNode> replacement

	enum RefactoringType {
		NEW_METHOD,
		METHOD_LIFT,
		FIELD_LIFT
	}
	
	protected new(String matchingPatternString, String replacementPatternString) {
		nameBindings.clear
		typeBindings.clear
		parameterBindings.clear
		visibilityBindings.clear
		argumentBindings.clear
		setMetaVariables
		this.matcher = new PatternMatcher(PatternParser.parse(matchingPatternString))
		this.builder = new ASTBuilder(PatternParser.parse(replacementPatternString))
		this.matchingString = matchingPatternString
		this.replacementString = replacementPatternString
		this.refactoringType = if(replacementPatternString != "nothing") {
			RefactoringType.NEW_METHOD
		} else {
			if(PatternParser.parse(matchingPatternString).patterns.head instanceof PMethodDeclaration) {
				RefactoringType.METHOD_LIFT
			} else {
				RefactoringType.FIELD_LIFT
			}
		}
		
		if (replacementString == "nothing" && definitionString == "target") {
			this.definitionString = matchingString
			this.definitionTypeReferenceString = matchingTypeReferenceString
		}
	}
	
	override init(List<? extends ASTNode> target, IDocument document, List<TypeDeclaration> allTypeDeclInWorkspace) {
		this.target = target
		this.document = document
		Check.allTypeDeclarationInWorkSpace = allTypeDeclInWorkspace
	}
	
	override apply() {
		return if(!safeTargetCheck) {
			Status.TARGET_MATCH_FAILED
		} else if (!safeMatch) {
			Status.MATCH_FAILED
		} else if (!safeCheck) {
			Status.CHECK_FAILED
		} else if (!safeBuild) {
			Status.BUILD_FAILED
		} else if (!safeReplace) {
			Status.REPLACEMENT_FAILED
		} else {
			Status.SUCCESS
		}
	}
	
	def private safeMatch() {
		try {
			if (!matcher.match(target, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, matchingTypeReferenceString)) {
				return false
			}
			target = matcher.modifiedTarget.toList
			bindings.putAll(matcher.bindings)
			true
		} catch (Exception e) {
			println(e)
			false
		}
	}
	
	def protected void setMetaVariables() {
		//empty
	}
	
	def protected safeTargetCheck() {
		true
	}
	
	def protected targetCheck(String targetPatternString) {
		try {
			this.targetString = targetPatternString
			if(!matcher.match(PatternParser.parse(targetPatternString), target, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, targetTypeReferenceString)) {
				return false
			}
			bindings.putAll(matcher.bindings)
			true
		} catch (Exception e) {
			println(e)
			false
		}
	}

	def private safeCheck() {
		try {
			check()
		} catch (Exception e) {
			println(e)
			false
		}
	}

	def protected check() {
		
		if(refactoringType == RefactoringType.NEW_METHOD) {
			
			val iCompUnit = Utils.getICompilationUnit(target.head)
			val compUnit = Utils.parseSourceCode(iCompUnit)
			compUnit.recordModifications
			
			val definitionPattern = PatternParser.parse(definitionString)
			val newMethod = builder.build(definitionPattern, compUnit.AST, bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, definitionTypeReferenceString).head as MethodDeclaration
			val targetClass = compUnit.types.findFirst[(it as TypeDeclaration).resolveBinding.qualifiedName == Utils.getTypeDeclaration(target.head).resolveBinding.qualifiedName ] as TypeDeclaration
			targetClass.bodyDeclarations.add(newMethod)
			Utils.applyChanges(compUnit, document)
			
			val compUnit2 = Utils.parseSourceCode(iCompUnit)
			val targetClass2 = compUnit2.types.findFirst[(it as TypeDeclaration).resolveBinding.qualifiedName == Utils.getTypeDeclaration(target.head).resolveBinding.qualifiedName] as TypeDeclaration
			val newMethodInClass = targetClass2.bodyDeclarations.last
			val List<ASTNode> definition = newArrayList
			definition.add(newMethodInClass)
			
			val overrideCheck = if(isOverrideIn(getMethodName(definition), parameters(definition), enclosingClass(target))) {
					!isLessVisible(visibility(definition), visibility(overridenMethodFrom(getMethodName(definition), parameters(definition), enclosingClass(target))))
					&& isSubTypeOf(type(definition), type(overridenMethodFrom(getMethodName(definition), parameters(definition), enclosingClass(target))))
					&& visibility(overridenMethodFrom(getMethodName(definition), parameters(definition), enclosingClass(target))) != Visibility.PUBLIC
					&& publicReferences(getMethodName(definition), parameters(definition), enclosingClass(target)).empty } else { true }
			
			val safeCheck = isUniqueMethodIn(getMethodName(definition), parameters(definition), enclosingClass(target))
				&& overrideCheck
					&& overridesOf(getMethodName(definition), parameters(definition), enclosingClass(target)).forall[
							!isLessVisible(visibility(it), visibility(definition)) &&
							isSubTypeOf(type(it), type(definition))]

			compUnit2.recordModifications
			targetClass2.bodyDeclarations.remove(newMethodInClass)
			Utils.applyChanges(compUnit2, document)
			safeCheck
			
		} else {
			if(refactoringType == RefactoringType.METHOD_LIFT) {
				
				val privateCheck = if (isPrivate(target)) { references(target, enclosingClass(target)).empty } else { true }
				val overrideCheck = if(isOverrideIn(getMethodName(target), parameters(target), superClass(enclosingClass(target)))) {
						!isLessVisible(visibility(target), visibility(overridenMethodFrom(getMethodName(target), parameters(target), superClass(enclosingClass(target))))) 
						&& isSubTypeOf(type(target), type(overridenMethodFrom(getMethodName(target), parameters(target), superClass(enclosingClass(target)))))
						&& visibility(overridenMethodFrom(getMethodName(target), parameters(target), superClass(enclosingClass(target)))) != Visibility.PUBLIC
						&& publicReferences(getMethodName(target), parameters(target), superClass(enclosingClass(target))).empty } else { true } 
				
				return hasSuperClass(enclosingClass(target))
					&& privateCheck
					&& accessedFieldsOfEnclosingClass(target, enclosingClass(target)).empty
					&& accessedMethodsOfEnclosingClass(target, enclosingClass(target)).empty
					&& isUniqueMethodIn(getMethodName(target), parameters(target), superClass(enclosingClass(target)))
					&& overrideCheck
					&& overridesOf(getMethodName(target), parameters(target), superClass(enclosingClass(target))).forall[
						!isLessVisible(visibility(it), visibility(target)) &&
						isSubTypeOf(type(it), type(target))]
						
			} else if (refactoringType == RefactoringType.FIELD_LIFT) {
				
				val privateCheck = if (isPrivate(target)) { references(target, enclosingClass(target)).empty } else { true }
				return hasSuperClass(enclosingClass(target))
					&& privateCheck
					&& isUniqueFieldIn(getFragmentNames(target), superClass(enclosingClass(target)))
					&& publicReferences(getFragmentNames(target), superClass(enclosingClass(target))).empty
					&& nonPublicReferences(getFragmentNames(target), superClass(enclosingClass(target))).forall [
						isSubTypeOf(Check.type(target), type(referredField(it))) ]
			}
			false
		}
	}

	def private safeBuild() {
		try {
			if(refactoringType == RefactoringType.NEW_METHOD) {
				val replacementPattern = PatternParser.parse(replacementString)
				replacement = builder.build(replacementPattern, target.head.AST, bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, definitionTypeReferenceString)
			}
			true
		} catch (Exception e) {
			println(e)
			false
		}
	}

	def private safeReplace() {
		try {
			//we only need to replace if we creating a new method
			if (refactoringType == RefactoringType.NEW_METHOD) {
				val rewrite = builder.rewrite
				target.tail.forEach[rewrite.remove(it, null)]
			
				val group = rewrite.createGroupNode(replacement)
				rewrite.replace( target.head, group, null)
				var edits = rewrite.rewriteAST(document, null)
				edits.apply(document)
			}
			
			val targetTypeDeclaration = Utils.getTypeDeclaration(target.head)
			var superClass = superClass(targetTypeDeclaration)
			val superCompUnit = Utils.getCompilationUnit(superClass)
			val superICompUnit = Utils.getICompilationUnit(superCompUnit)
			
			val targetICompUnit = Utils.getICompilationUnit(target.head)
			val targetCompUnit = Utils.parseSourceCode(targetICompUnit)
			targetCompUnit.recordModifications
			
			val definitionPattern = PatternParser.parse(definitionString)
			var objectToInsertOrMove = builder.build(definitionPattern, targetCompUnit.AST, bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, definitionTypeReferenceString).head
			val targetClass = targetCompUnit.types.findFirst[(it as TypeDeclaration).name.identifier == targetTypeDeclaration.name.identifier] as TypeDeclaration
			
			if(refactoringType == RefactoringType.NEW_METHOD) {
				targetClass.bodyDeclarations.add(objectToInsertOrMove)
			} else {
				if(superICompUnit != targetICompUnit) {
					superCompUnit.recordModifications
					objectToInsertOrMove = builder.build(definitionPattern, superCompUnit.AST , bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, definitionTypeReferenceString).head
				} else {
					superClass = targetCompUnit.types.findFirst[(it as TypeDeclaration).resolveBinding.isEqualTo(targetClass.superclassType.resolveBinding)]
				}
				
				val methodOrFieldToDelete = if(refactoringType == RefactoringType.METHOD_LIFT){
					getMethodFromClass(getMethodName(target), parameters(target), targetClass)
				} else if (refactoringType == RefactoringType.FIELD_LIFT) {
					targetClass.bodyDeclarations.findFirst[it instanceof FieldDeclaration && 
						((it as FieldDeclaration).fragments.head as VariableDeclarationFragment).name.identifier == ((target.head as FieldDeclaration).fragments.head as VariableDeclarationFragment).name.identifier]
				}
				
				superClass.bodyDeclarations.add(objectToInsertOrMove)
				targetClass.bodyDeclarations.remove(methodOrFieldToDelete)
				
				if(superICompUnit != targetICompUnit) {
					val superDocument = new Document(superICompUnit.source)
					Utils.applyChanges(superCompUnit, superDocument)
					superICompUnit.getBuffer.setContents(superDocument.get)
				}
			}
			Utils.applyChanges(targetCompUnit, document)
			true
		} catch (Exception e) {
			println(e)
			return false
		}
	}
}