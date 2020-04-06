package hu.elte.refjava.api

import hu.elte.refjava.api.patterns.ASTBuilder
import hu.elte.refjava.api.patterns.PatternMatcher
import hu.elte.refjava.api.patterns.PatternParser
import hu.elte.refjava.api.patterns.Utils
import java.lang.reflect.Type
import java.util.List
import java.util.Map
import org.eclipse.jdt.core.ICompilationUnit
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.FieldDeclaration
import org.eclipse.jdt.core.dom.MethodDeclaration
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jdt.core.dom.VariableDeclarationFragment
import org.eclipse.jface.text.IDocument
import org.eclipse.jdt.core.dom.ASTParser
import org.eclipse.jdt.core.dom.CompilationUnit
import org.eclipse.jdt.core.dom.AST
import org.eclipse.jface.text.IRewriteTarget
import org.eclipse.jface.text.Document

class ClassRefactoring implements Refactoring {
	
	List<? extends ASTNode> target
	List<TypeDeclaration> typeDeclList
	IDocument document
	
	
	val PatternMatcher matcher
	val ASTBuilder builder
	val String matchingString
	val String replacementString
	protected String targetString
	protected String definitionString
	protected val Map<String, List<? extends ASTNode>> bindings = newHashMap
	protected val Map<String, String> nameBindings = newHashMap
	protected val Map<String, Type> typeBindings = newHashMap
	protected val Map<String, List<Pair<Type, String>>> parameterBindings = newHashMap
	protected String matchingTypeReferenceString
	protected String replacementTypeReferenceString
	protected String targetTypeReferenceString
	protected String definitionTypeReferenceString
	List<ASTNode> replacement

	protected new(String matchingPatternString, String replacementPatternString) {
		matcher = new PatternMatcher(PatternParser.parse(matchingPatternString))
		builder = new ASTBuilder(PatternParser.parse(replacementPatternString))
		this.matchingString = matchingPatternString
		this.replacementString = replacementPatternString
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
		//TODO
		if(replacementString != "-") {
			//return Check.isUniqueMethodIn(target, Check.enclosingClass(target))
			
			return true
			
			
		} else {
			if(target.head instanceof MethodDeclaration) {
				return Check.hasSuperClass(Check.enclosingClass(target))
					&& if (Check.isPrivate(target)) Check.references(target, Check.enclosingClass(target)).empty else true
					&& Check.accessedFieldsOfEnclosingClass(target, Check.enclosingClass(target)).empty
					&& Check.accessedMethodsOfEnclosingClass(target, Check.enclosingClass(target)).empty
				//	&& Check.isUniqueMethodIn(target, Check.superClass(Check.enclosingClass(target)))
					
				
			} else if (target.head instanceof FieldDeclaration) {
				return Check.hasSuperClass(Check.enclosingClass(target))
					&& if (Check.isPrivate(target)) Check.references(target, Check.enclosingClass(target)).empty else true
				//	&& Check.isUniqueFieldIn(target, Check.superClass(Check.enclosingClass(target)))
			}
			return false
		}
	}

	def private safeBuild() {
		try {
			if(replacementString != "-") {
				replacement = builder.build(target.head.AST, bindings, nameBindings, typeBindings, parameterBindings, replacementTypeReferenceString)
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
			if (replacement !== null) {
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
			parser.source = targetICompUnit;
			val targetCompUnit = parser.createAST(null) as CompilationUnit;
			
			targetCompUnit.recordModifications
			
			if (replacementString == "-" && definitionString == "target" && matchingString == "target") {
				definitionString = targetString
				definitionTypeReferenceString = targetTypeReferenceString
			} else if (replacementString == "-" && definitionString == "target" && matchingString != "target") {
				definitionString = matchingString
				definitionTypeReferenceString = matchingTypeReferenceString
			}
			
			val definitionPattern = PatternParser.parse(definitionString)
			var objectToInsertOrMove = builder.build(definitionPattern, targetCompUnit.AST, bindings, nameBindings, typeBindings, parameterBindings, definitionTypeReferenceString).head
			
			val targetTypeDeclaration = Utils.getTypeDeclaration(target.head)
			val targetClass = targetCompUnit.types.findFirst[ (it as TypeDeclaration).name.identifier == targetTypeDeclaration.name.identifier ] as TypeDeclaration
			
			var CompilationUnit superCompUnit
			var ICompilationUnit superICompUnit
			
			if(replacement !== null) {
				targetClass.bodyDeclarations.add(objectToInsertOrMove)
			} else {
				val superClassType = targetTypeDeclaration.superclassType
				
				
				//needs work
				var superClass = typeDeclList.findFirst[ (it as TypeDeclaration).name.identifier == superClassType.toString] as TypeDeclaration
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
				if(target.head instanceof MethodDeclaration){
					methodOrFieldToDelete = targetClass.bodyDeclarations.findFirst[ it instanceof MethodDeclaration && (it as MethodDeclaration).name.identifier == (target.head as MethodDeclaration).name.identifier ]
				} else if (target.head instanceof FieldDeclaration) {
					methodOrFieldToDelete = targetClass.bodyDeclarations.findFirst[ it instanceof FieldDeclaration && ((it as FieldDeclaration).fragments.head as VariableDeclarationFragment).name.identifier == ((target.head as FieldDeclaration).fragments.head as VariableDeclarationFragment).name.identifier ]
				}
				
				superClass.bodyDeclarations.add(objectToInsertOrMove)
				targetClass.bodyDeclarations.remove(methodOrFieldToDelete)
			}
			
			val edits2 = targetCompUnit.rewrite(document, targetICompUnit.javaProject.getOptions(true))
			edits2.apply(document)
			val newSource = document.get;	
			targetICompUnit.getBuffer().setContents(newSource);
			
			if(superICompUnit != targetICompUnit) {
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