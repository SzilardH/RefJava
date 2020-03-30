package hu.elte.refjava.api

import hu.elte.refjava.api.patterns.ASTBuilder
import hu.elte.refjava.api.patterns.PatternMatcher
import hu.elte.refjava.api.patterns.PatternParser
import java.lang.reflect.Type
import java.util.List
import java.util.Map
import java.util.Queue
import org.eclipse.jdt.core.ICompilationUnit
import org.eclipse.jdt.core.dom.AST
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.ASTParser
import org.eclipse.jdt.core.dom.CompilationUnit
import org.eclipse.jdt.core.dom.FieldDeclaration
import org.eclipse.jdt.core.dom.MethodDeclaration
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jdt.core.dom.VariableDeclarationFragment
import org.eclipse.jface.text.IDocument
import hu.elte.refjava.api.patterns.Utils
import java.lang.reflect.Modifier

class ClassRefactoring implements Refactoring {
	
	List<? extends ASTNode> target
	IDocument document
	ICompilationUnit iCompUnit
	
	val PatternMatcher matcher
	val ASTBuilder builder
	val String matchingString
	val String replacementString
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
	
	override init(List<? extends ASTNode> target, IDocument document, ICompilationUnit iCompUnit) {
		this.target = target
		this.document = document
		this.iCompUnit = iCompUnit
	}
	
	def setTarget(List<?extends ASTNode> newTarget) {
		this.target = newTarget
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
			setMetaVariables()
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
		return matcher.match(PatternParser.parse(targetPatternString), target, targetTypeReferenceString)
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
		
		val ASTParser parser = ASTParser.newParser(AST.JLS12);
		parser.setSource(iCompUnit);
		val CompilationUnit compUnit = parser.createAST(null) as CompilationUnit;
		
		if (replacementString == "-" && definitionString == "target") {
			definitionString = matchingString
			definitionTypeReferenceString = matchingTypeReferenceString
		}
		
		val targetTypeDeclaration = Utils.getTypeDeclaration(target.head)
		val definitionPattern = PatternParser.parse(definitionString)
		val definitionToCheck = builder.build(definitionPattern, compUnit.AST, bindings, nameBindings, typeBindings, parameterBindings, definitionTypeReferenceString).head
		
		if(replacementString != "-") {
			println("lambda to method check")
		} else {
			val superClass = compUnit.types.findFirst[ (it as TypeDeclaration).name.identifier == targetTypeDeclaration.superclassType.toString] as TypeDeclaration
			val targetClass = compUnit.types.findFirst[ (it as TypeDeclaration).name.identifier == targetTypeDeclaration.name.identifier ] as TypeDeclaration
			if(target.head instanceof MethodDeclaration) {
				println("method lift check")
				
				return targetTypeDeclaration.superclassType !== null
				
				
			} else if (target.head instanceof FieldDeclaration) {
				println("field lift check")
				val field = definitionToCheck as FieldDeclaration
				
				
				println("1 " + (targetTypeDeclaration.superclassType !== null))
				println("2 ")
				println("3 " + !superClass.bodyDeclarations.exists[(it instanceof FieldDeclaration) && 
						((it as FieldDeclaration).fragments.head as VariableDeclarationFragment).name.identifier == (field.fragments.head as VariableDeclarationFragment).name.identifier
					])
				println("4 ")
				println("5 ")
				
				
				return targetTypeDeclaration.superclassType !== null && 
					if (Modifier.isPrivate(field.getModifiers())) {
						//TODO
						
						
						
						return false
					} else {
						true
					} 
					&& !superClass.bodyDeclarations.exists[(it instanceof FieldDeclaration) && 
						((it as FieldDeclaration).fragments.head as VariableDeclarationFragment).name.identifier == (field.fragments.head as VariableDeclarationFragment).name.identifier
					]
			}
		}
		
		
		
		return false
	}

	def private safeBuild() {
		try {
			if(replacementString != "-") {
				val replacementPattern = PatternParser.parse(replacementString)
				replacement = builder.build(replacementPattern, target.head.AST, bindings, nameBindings, typeBindings, parameterBindings, replacementTypeReferenceString)
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
			
			//we create the type references for the definition
			var Queue<String> definitionTypeReferenceQueue = newLinkedList
			if(definitionTypeReferenceString !== null) {
				val tmp = definitionTypeReferenceString.split("\\|")
				definitionTypeReferenceQueue.addAll(tmp)
			}
			
			val ASTParser parser = ASTParser.newParser(AST.JLS12);
			parser.setSource(iCompUnit);
			val CompilationUnit compUnit = parser.createAST(null) as CompilationUnit;
			compUnit.recordModifications
			
			val definitionPattern = PatternParser.parse(definitionString)
			val objectToInsertOrMove = builder.build(definitionPattern, compUnit.AST, bindings, nameBindings, typeBindings, parameterBindings, definitionTypeReferenceString).head
			
			val targetTypeDeclaration = Utils.getTypeDeclaration(target.head)
			val targetClass = compUnit.types.findFirst[ (it as TypeDeclaration).name.identifier == targetTypeDeclaration.name.identifier ] as TypeDeclaration
			
			if(replacement !== null) {
				targetClass.bodyDeclarations.add(objectToInsertOrMove)
			} else {
				val superClassType = targetTypeDeclaration.superclassType
				val superClass = compUnit.types.findFirst[ (it as TypeDeclaration).name.identifier == superClassType.toString] as TypeDeclaration
				
				var Object methodOrFieldToDelete
				if(target.head instanceof MethodDeclaration){
					methodOrFieldToDelete = targetClass.bodyDeclarations.findFirst[ it instanceof MethodDeclaration && (it as MethodDeclaration).name.identifier == (target.head as MethodDeclaration).name.identifier ]
				} else if (target.head instanceof FieldDeclaration) {
					methodOrFieldToDelete = targetClass.bodyDeclarations.findFirst[ it instanceof FieldDeclaration && ((it as FieldDeclaration).fragments.head as VariableDeclarationFragment).name.identifier == ((target.head as FieldDeclaration).fragments.head as VariableDeclarationFragment).name.identifier ]
				}
				superClass.bodyDeclarations.add(objectToInsertOrMove)
				targetClass.bodyDeclarations.remove(methodOrFieldToDelete)
			}
			val edits2 = compUnit.rewrite(document, iCompUnit.javaProject.getOptions(true))
			edits2.apply(document)
			val String newSource = document.get;	
			iCompUnit.getBuffer().setContents(newSource);
			
		} catch (Exception e) {
			println(e)
			return false
		}
		return true
	}
}