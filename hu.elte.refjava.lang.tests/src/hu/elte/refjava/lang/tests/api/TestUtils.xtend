package hu.elte.refjava.lang.tests.api

import hu.elte.refjava.api.patterns.ASTBuilder
import hu.elte.refjava.api.patterns.PatternMatcher
import hu.elte.refjava.api.patterns.PatternParser
import hu.elte.refjava.lang.refJava.Visibility
import java.util.List
import java.util.Map
import org.eclipse.jdt.core.dom.AST
import org.eclipse.jdt.core.dom.ASTParser
import org.eclipse.jdt.core.dom.CompilationUnit
import org.eclipse.jdt.core.dom.Expression
import org.eclipse.jdt.core.dom.MethodDeclaration
import org.eclipse.jdt.core.dom.SingleVariableDeclaration
import org.eclipse.jdt.core.dom.Type
import org.eclipse.jdt.core.dom.TypeDeclaration

import static org.junit.jupiter.api.Assertions.*
import org.eclipse.jdt.core.dom.ASTNode

class TestUtils {
	
	def static getCompliationUnit(String str) {
		val parser = ASTParser.newParser(AST.JLS12);		
		parser.setUnitName("test.java");
		parser.setEnvironment(null, null, null, true);
		parser.resolveBindings = true
		parser.source = str.toCharArray
		val newCompUnit = parser.createAST(null) as CompilationUnit
		newCompUnit
	}
	
	def static void testMatcher(String patternString, String sourceString, String declarationSource, Map<String, String> nameBindings, Map<String, Type> typeBindings, Map<String, List<SingleVariableDeclaration>> parameterBindings, Map<String, Visibility> visibilityBindings, Map<String, List<Expression>> argumentBindings, String typeRefString) {
		val matcher = new PatternMatcher(null)
		val pattern = PatternParser.parse(patternString)
		val source = TestUtils.getCompliationUnit(sourceString)
		val matchings = if(declarationSource == "block") {
			((source.types.head as TypeDeclaration).bodyDeclarations.head as MethodDeclaration).body.statements
		} else if(declarationSource == "class") {
			(source.types.head as TypeDeclaration).bodyDeclarations
		}
		assertTrue(matcher.match(pattern, matchings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString))
	}
	
	def static testBuilder(String patternString, Map<String, List<? extends ASTNode>> bindings, Map<String, String> nameBindings, Map<String, Type> typeBindings, Map<String, List<SingleVariableDeclaration>> parameterBindings, Map<String, Visibility> visibilityBindings, Map<String, List<Expression>> argumentBindings, String typeRefString) {
		val builder = new ASTBuilder(null)
		val pattern = PatternParser.parse(patternString)
		val source = TestUtils.getCompliationUnit("")
		builder.build(pattern, source.AST, bindings, nameBindings, typeBindings, parameterBindings, visibilityBindings, argumentBindings, typeRefString)
	}
	
}