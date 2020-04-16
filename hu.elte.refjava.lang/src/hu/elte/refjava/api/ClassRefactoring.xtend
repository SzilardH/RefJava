package hu.elte.refjava.api

import hu.elte.refjava.api.patterns.ASTBuilder
import hu.elte.refjava.api.patterns.PatternMatcher
import hu.elte.refjava.api.patterns.PatternParser
import hu.elte.refjava.api.patterns.Utils
import hu.elte.refjava.lang.refJava.PMethodDeclaration
import java.util.List
import org.eclipse.jdt.core.ICompilationUnit
import org.eclipse.jdt.core.dom.AST
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.ASTParser
import org.eclipse.jdt.core.dom.CompilationUnit
import org.eclipse.jdt.core.dom.FieldDeclaration
import org.eclipse.jdt.core.dom.MethodDeclaration
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jdt.core.dom.VariableDeclarationFragment
import org.eclipse.jface.text.Document
import org.eclipse.jface.text.IDocument

import static hu.elte.refjava.api.Check.*

class ClassRefactoring implements Refactoring {
	
	List<? extends ASTNode> target
	List<TypeDeclaration> typeDeclList
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
		matcher = new PatternMatcher(PatternParser.parse(matchingPatternString))
		builder = new ASTBuilder(PatternParser.parse(replacementPatternString))
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
	}
	
	override init(List<? extends ASTNode> target, IDocument document, List<TypeDeclaration> allTypeDeclInWorkspace) {
		this.target = target
		this.document = document
		this.typeDeclList = allTypeDeclInWorkspace
	}
	
	def setTarget(List<?extends ASTNode> newTarget) {
		this.target = newTarget
	}
	
	override apply() {
		setMetaVariables()
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
			if (!matcher.match(target, nameBindings, typeBindings, parameterBindings, matchingTypeReferenceString)) {
				return false
			}
			target = matcher.modifiedTarget.toList
			bindings.putAll(matcher.bindings)
			
			return true
		} catch (Exception e) {
			println(e)
			return false
		}
	}
	
	def protected void setMetaVariables() {
		//empty
	}
	
	def protected safeTargetCheck() {
		return true
	}
	
	def protected targetCheck(String targetPatternString) {
		try {
			this.targetString = targetPatternString
			if(!matcher.match(PatternParser.parse(targetPatternString), target, targetTypeReferenceString)) {
				return false
			}
			bindings.putAll(matcher.bindings)
			return true
		} catch (Exception e) {
			println(e)
			return false
		}	
	}

	def private safeCheck() {
		try {
			return check()
		} catch (Exception e) {
			println(e)
			return false
		}
	}

	def protected check() {
		
		Check.allTypeDeclarationInWorkSpace = typeDeclList
		
		if (replacementString == "nothing" && definitionString == "target" && matchingString == "target") {
			definitionString = targetString
			definitionTypeReferenceString = targetTypeReferenceString
		} else if (replacementString == "nothing" && definitionString == "target" && matchingString != "target") {
			definitionString = matchingString
			definitionTypeReferenceString = matchingTypeReferenceString
		}
		
		if(refactoringType == RefactoringType.NEW_METHOD) {
			
			val compUnit = Utils.getCompilationUnit(target.head)
			val iCompUnit = compUnit.getJavaElement() as ICompilationUnit
			
			val parser = ASTParser.newParser(AST.JLS12);
			parser.resolveBindings = true
			parser.source = iCompUnit;
			val newCompUnit = parser.createAST(null) as CompilationUnit;
			newCompUnit.recordModifications
			
			val definitionPattern = PatternParser.parse(definitionString)
			val newMethod = builder.build(definitionPattern, newCompUnit.AST, bindings, nameBindings, typeBindings, parameterBindings, definitionTypeReferenceString).head

			val targetClass = newCompUnit.types.findFirst[(it as TypeDeclaration).resolveBinding.qualifiedName == Utils.getTypeDeclaration(target.head).resolveBinding.qualifiedName ] as TypeDeclaration
			targetClass.bodyDeclarations.add(newMethod)

			val edits2 = newCompUnit.rewrite(document, iCompUnit.javaProject.getOptions(true))
			edits2.apply(document)
			val newSource = document.get;	
			iCompUnit.getBuffer().setContents(newSource);
			
			val parser2 = ASTParser.newParser(AST.JLS12);
			parser2.resolveBindings = true
			parser2.source = iCompUnit
			val newCompUnit2 = parser2.createAST(null) as CompilationUnit;
			
			val targetClass2 = newCompUnit2.types.findFirst[(it as TypeDeclaration).resolveBinding.qualifiedName == Utils.getTypeDeclaration(target.head).resolveBinding.qualifiedName] as TypeDeclaration
			val newMethodInClass = targetClass2.bodyDeclarations.findFirst[it instanceof MethodDeclaration && (it as MethodDeclaration).name.identifier == (newMethod as MethodDeclaration).name.identifier] as MethodDeclaration
			
			val List<ASTNode> definition = newArrayList
			definition.add(newMethodInClass)
			
			val safeCheck = Check.isUniqueMethodIn(Check.getMethodName(definition), Check.parameters(definition), Check.enclosingClass(target))
				&& if(Check.isOverrideIn(Check.getMethodName(definition), Check.parameters(definition), Check.enclosingClass(target))) {
					!Check.isLessVisible(Check.visibility(definition), Check.visibility(Check.overridenMethodFrom(Check.getMethodName(definition), Check.parameters(definition), Check.enclosingClass(target))))
					&& Check.isSubTypeOf(Check.type(definition), Check.type(Check.overridenMethodFrom(Check.getMethodName(definition), Check.parameters(definition), Check.enclosingClass(target))))
					&& Check.visibility(Check.overridenMethodFrom(Check.getMethodName(definition), Check.parameters(definition), Check.enclosingClass(target))) != "public" 
					&& Check.publicReferences(Check.getMethodName(definition), Check.parameters(definition), Check.enclosingClass(target)).empty
					&& false
				} else {
					true
				}
				
			newCompUnit2.recordModifications
			targetClass2.bodyDeclarations.remove(newMethodInClass)
			
			val edits3 = newCompUnit2.rewrite(document, iCompUnit.javaProject.getOptions(true))
			edits3.apply(document)
			val newSource2 = document.get;	
			iCompUnit.getBuffer().setContents(newSource2);
			
			return safeCheck
			
		} else {
			if(refactoringType == RefactoringType.METHOD_LIFT) {
				
				return Check.hasSuperClass(Check.enclosingClass(target))
					&& if (Check.isPrivate(target)) Check.references(target, Check.enclosingClass(target)).empty else true
					&& Check.accessedFieldsOfEnclosingClass(target, Check.enclosingClass(target)).empty
					&& Check.accessedMethodsOfEnclosingClass(target, Check.enclosingClass(target)).empty
					&& Check.isUniqueMethodIn(Check.getMethodName(target), Check.parameters(target), Check.superClass(Check.enclosingClass(target)))
					&& if(Check.isOverrideIn(Check.getMethodName(target), Check.parameters(target), Check.superClass(Check.enclosingClass(target)))) {
						!Check.isLessVisible(Check.visibility(target), Check.visibility(Check.overridenMethodFrom(Check.getMethodName(target), Check.parameters(target), Check.superClass(Check.enclosingClass(target))))) 
						&& Check.isSubTypeOf(Check.type(target), Check.type(Check.overridenMethodFrom(Check.getMethodName(target), Check.parameters(target), Check.superClass(Check.enclosingClass(target)))))
						&& Check.visibility(Check.overridenMethodFrom(Check.getMethodName(target), Check.parameters(target), Check.superClass(Check.enclosingClass(target)))) != "public" 
						&& Check.publicReferences(Check.getMethodName(target), Check.parameters(target), Check.superClass(Check.enclosingClass(target))).empty
						
						
						} else {
							true
						}
						//TODO
					
			} else if (refactoringType == RefactoringType.FIELD_LIFT) {
				
				return Check.hasSuperClass(Check.enclosingClass(target))
					&& if (Check.isPrivate(target)) Check.references(target, Check.enclosingClass(target)).empty else true
					&& Check.isUniqueFieldIn(Check.getFragmentNames(target), Check.superClass(Check.enclosingClass(target)))
					&& Check.publicReferences(Check.getFragmentNames(target), Check.superClass(Check.enclosingClass(target))).empty
					&& Check.privateReferences(Check.getFragmentNames(target), Check.superClass(Check.enclosingClass(target))).forall [
						Check.isSubTypeOf(Check.type(target), Check.referredField(it).type) ]
			}
			return false
		}
	}

	def private safeBuild() {
		try {
			if(refactoringType == RefactoringType.NEW_METHOD) {
				val replacementPattern = PatternParser.parse(replacementString)
				replacement = builder.build(replacementPattern, target.head.AST, bindings, nameBindings, typeBindings, parameterBindings, definitionTypeReferenceString)
			}
		} catch (Exception e) {
			println(e)
			return false
		}
		return true
	}

	def private safeReplace() {
		try {
			//we only need to replace if we creating a new method
			if (refactoringType == RefactoringType.NEW_METHOD) {
				val rewrite = builder.rewrite
				target.tail.forEach[rewrite.remove(it, null)]
			
				val group = rewrite.createGroupNode( replacement )
				rewrite.replace( target.head, group, null)
				var edits = rewrite.rewriteAST(document, null)
				edits.apply(document)
			}
			
			val compUnit = Utils.getCompilationUnit(target.head)
			val targetICompUnit = compUnit.getJavaElement() as ICompilationUnit
			
			val parser = ASTParser.newParser(AST.JLS12);
			parser.resolveBindings = true
			parser.source = targetICompUnit;
			val targetCompUnit = parser.createAST(null) as CompilationUnit;
			
			targetCompUnit.recordModifications
			
			val definitionPattern = PatternParser.parse(definitionString)
			var objectToInsertOrMove = builder.build(definitionPattern, targetCompUnit.AST, bindings, nameBindings, typeBindings, parameterBindings, definitionTypeReferenceString).head
			
			val targetTypeDeclaration = Utils.getTypeDeclaration(target.head)
			val targetClass = targetCompUnit.types.findFirst[ (it as TypeDeclaration).name.identifier == targetTypeDeclaration.name.identifier ] as TypeDeclaration
			
			var CompilationUnit superCompUnit
			var ICompilationUnit superICompUnit = null
			
			if(refactoringType == RefactoringType.NEW_METHOD) {
				targetClass.bodyDeclarations.add(objectToInsertOrMove)
			} else {
				val superClassType = targetTypeDeclaration.superclassType
				val superClassTypeBinding = superClassType.resolveBinding
				
				//needs work
				var TypeDeclaration superClass
				for(t : typeDeclList) {
					if (t.resolveBinding.toString == superClassTypeBinding.toString) {
						superClass = t
					}
				}
				
				val compUnit2 = Utils.getCompilationUnit(superClass)
				superICompUnit = compUnit2.getJavaElement() as ICompilationUnit
				
				if (superICompUnit != targetICompUnit) {
					superCompUnit = Utils.getCompilationUnit(superClass)
					superICompUnit = superCompUnit.getJavaElement() as ICompilationUnit
					superClass = superCompUnit.types.findFirst[ (it as TypeDeclaration).name.identifier == superClassType.toString] as TypeDeclaration
					superCompUnit.recordModifications
					objectToInsertOrMove = builder.build(definitionPattern, superCompUnit.AST, bindings, nameBindings, typeBindings, parameterBindings, definitionTypeReferenceString).head
				} else {
					superClass = targetCompUnit.types.findFirst[ (it as TypeDeclaration).name.identifier == superClassType.toString] as TypeDeclaration
				}
				
				var Object methodOrFieldToDelete
				if(refactoringType == RefactoringType.METHOD_LIFT){
					methodOrFieldToDelete = targetClass.bodyDeclarations.findFirst[ it instanceof MethodDeclaration && (it as MethodDeclaration).name.identifier == (target.head as MethodDeclaration).name.identifier ]
				} else if (refactoringType == RefactoringType.FIELD_LIFT) {
					methodOrFieldToDelete = targetClass.bodyDeclarations.findFirst[ it instanceof FieldDeclaration && ((it as FieldDeclaration).fragments.head as VariableDeclarationFragment).name.identifier == ((target.head as FieldDeclaration).fragments.head as VariableDeclarationFragment).name.identifier ]
				}
				
				superClass.bodyDeclarations.add(objectToInsertOrMove)
				targetClass.bodyDeclarations.remove(methodOrFieldToDelete)
			}
			
			val edits2 = targetCompUnit.rewrite(document, targetICompUnit.javaProject.getOptions(true))
			edits2.apply(document)
			val newSource = document.get;	
			targetICompUnit.getBuffer().setContents(newSource);
			
			
			if(superICompUnit !== null && superICompUnit != targetICompUnit) {
				val superDocument = new Document(superICompUnit.source)
				val edits3 = superCompUnit.rewrite(superDocument, superICompUnit.javaProject.getOptions(true))
				edits3.apply(superDocument)
				val superSource = superDocument.get
				superICompUnit.getBuffer().setContents(superSource)
			}
		} catch (Exception e) {
			println(e)
			return false
		}
		return true
	}
}