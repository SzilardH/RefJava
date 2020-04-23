package hu.elte.refjava.lang.tests

import org.eclipse.jdt.core.dom.AST
import org.eclipse.jdt.core.dom.ASTParser
import org.eclipse.jdt.core.dom.CompilationUnit

class TestUtils {
	
	def static getCompliationUnit(String str) {
		val parser = ASTParser.newParser(AST.JLS12);
		parser.resolveBindings = true
		parser.source = str.toCharArray
		val newCompUnit = parser.createAST(null) as CompilationUnit
		newCompUnit
	}
	
}