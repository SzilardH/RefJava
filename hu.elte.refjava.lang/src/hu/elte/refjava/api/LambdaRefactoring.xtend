package hu.elte.refjava.api

import hu.elte.refjava.api.patterns.ASTBuilder
import hu.elte.refjava.api.patterns.PatternMatcher
import hu.elte.refjava.api.patterns.PatternParser
import hu.elte.refjava.lang.refJava.PLambdaExpression
import java.lang.reflect.Type
import java.util.List
import java.util.Map
import org.eclipse.jdt.core.ICompilationUnit
import org.eclipse.jdt.core.dom.AST
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.ASTParser
import org.eclipse.jdt.core.dom.CompilationUnit
import org.eclipse.jface.text.IDocument
import hu.elte.refjava.api.patterns.Utils
import org.eclipse.jdt.core.dom.TypeDeclaration

class LambdaRefactoring implements Refactoring {
	
	List<? extends ASTNode> target
	IDocument document
	
	val PatternMatcher matcher
	val ASTBuilder builder
	val String matchingString
	val String replacementString
	val String refactoringType
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
		val matchingPatternsFirstElement = PatternParser.parse(matchingPatternString).patterns.get(0)
		this.matchingString = matchingPatternString
		this.replacementString = replacementPatternString
		this.refactoringType = if (matchingPatternsFirstElement instanceof PLambdaExpression) {
			"modification"
		} else {
			"new"
		}
	}
	
	override init(List<? extends ASTNode> target, IDocument document, List<TypeDeclaration> allTypeDeclInWorkspace) {
		this.target = target
		this.document = document
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
		if(refactoringType == "new") {
			println("new lambda expression")
			
			
			
		} else {
			println("lambda expression modification")
			
			
		}
		return true
	}

	def private safeBuild() {
		try {
			replacement = builder.build(target.head.AST, bindings, nameBindings, typeBindings, parameterBindings, replacementTypeReferenceString)
		} catch (Exception e) {
			println(e)
			return false
		}
		return true
	}

	def private safeReplace() {
		try {
			val rewrite = builder.rewrite
			target.tail.forEach[rewrite.remove(it, null)]
			
			val group = rewrite.createGroupNode( replacement )
			rewrite.replace( target.head, group, null)
			var edits = rewrite.rewriteAST(document, null)
			edits.apply(document)
			
			
			val compUnit = Utils.getCompilationUnit(target.head)
			val iCompUnit= compUnit.getJavaElement() as ICompilationUnit
			
			val parser = ASTParser.newParser(AST.JLS12);
			parser.source = iCompUnit;
			val newcompUnit = parser.createAST(null) as CompilationUnit;
			
			newcompUnit.recordModifications
			
			if(refactoringType == "new") {
				println("create a new lambda and interface")
				
				val replacementLambdaExpression = PatternParser.parse(replacementString).patterns.get(0) as PLambdaExpression
				val newInterface = builder.buildNewInterface(replacementLambdaExpression, newcompUnit.AST, bindings, nameBindings, typeBindings, parameterBindings, replacementTypeReferenceString)
				newcompUnit.types().add(newInterface)
				
				
			} else {
				println("get the existing interface and modify it")
				
				
			}
			
			
			/*
			if(!compUnit.types.exists[ (it as TypeDeclaration).name.identifier == builder.newInterface.name.identifier]) {				
				val newInterface = compUnit.AST.newTypeDeclaration
				newInterface.interface = true
				newInterface.name.identifier = builder.newInterface.name.identifier
				for(method : builder.newInterface.bodyDeclarations) {
					val m = method as MethodDeclaration
					val newMethodDeclaration = compUnit.AST.newMethodDeclaration
					newMethodDeclaration.name.identifier = m.name.identifier
					newMethodDeclaration.returnType2 = Utils.getTypeFromId(m.returnType2.toString, compUnit.AST)
					newInterface.bodyDeclarations.add(newMethodDeclaration)
					for(arg : m.parameters ) {
						val a = arg as SingleVariableDeclaration
						val methodParameterDeclaration = compUnit.AST.newSingleVariableDeclaration
						methodParameterDeclaration.name.identifier = a.name.identifier
						methodParameterDeclaration.type = Utils.getTypeFromId(a.type.toString, compUnit.AST)
						newMethodDeclaration.parameters.add(methodParameterDeclaration)
					}
				}
				compUnit.types().add(newInterface)
			}
			*/
			
			val edits2 = newcompUnit.rewrite(document, iCompUnit.javaProject.getOptions(true) )
			edits2.apply(document);
		   	val String newSource = document.get();		
			iCompUnit.getBuffer().setContents(newSource);
			
		} catch (Exception e) {
			println(e)
			return false
		}
		return true
	}
}