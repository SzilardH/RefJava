package hu.elte.refjava.api.patterns

import hu.elte.refjava.lang.refJava.Pattern
import org.eclipse.jdt.core.dom.AST
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.CompilationUnit
import org.eclipse.jdt.core.dom.FieldDeclaration
import org.eclipse.jdt.core.dom.MethodDeclaration
import org.eclipse.jdt.core.dom.PrimitiveType
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jdt.core.dom.VariableDeclarationStatement
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.common.types.JvmTypeReference
import org.eclipse.jdt.core.ICompilationUnit

class Utils {
	
	def static getTypeFromId(String id, AST ast) {
		
		val primitiveTypes = newArrayList("byte", "short", "char", "int", "long", "float", "double", "boolean", "void")
		
		if(primitiveTypes.contains(id)) {
			//primitive type
			return ast.newPrimitiveType(PrimitiveType.toCode(id))
		} else if (id.contains("[") && id.contains("]")) {
			//array type		
			val char openingSymbol = '['
			val char closingSymbol = ']'
			var String type = ""
			var int dimension = 0
			for(var int i = 0; i < id.length; i++) {
				if( id.charAt(i).identityEquals(openingSymbol) ) {
					dimension++
				} else if ( !id.charAt(i).identityEquals(openingSymbol) && !id.charAt(i).identityEquals(closingSymbol)) {
					type += id.charAt(i)
				}
			}
			if(primitiveTypes.contains(type)) {
				//primitive array type
				return ast.newArrayType(ast.newPrimitiveType(PrimitiveType.toCode(type)), dimension)
			} else {
				//simple array type
				val simpleName = type.split("\\.")
				return ast.newArrayType(ast.newSimpleType(ast.newSimpleName(simpleName.last)), dimension)
			}
		} else {
			//simple type
			val simpleName = id.split("\\.").last
			return ast.newSimpleType(ast.newSimpleName(simpleName))
		}
	}

	
	
	def static getTypeReferenceString(Pattern pattern) {
		var String typeReferenceString = ""
		val types = EcoreUtil2.getAllContentsOfType(pattern, JvmTypeReference)
		for(type : types) {
			typeReferenceString = typeReferenceString + type.identifier + "|"
		}
		return typeReferenceString
	}
	
	def static getTypeDeclaration(ASTNode node) {
		var tmp = node
			while (!(tmp instanceof TypeDeclaration)) {
				tmp = tmp.parent
		}
		tmp as TypeDeclaration
	}
	
	def static getCompilationUnit(ASTNode node) {
		var tmp = node
			while (!(tmp instanceof CompilationUnit)) {
				tmp = tmp.parent
		}
		tmp as CompilationUnit
	}
	
	def static getMethodDeclaration(ASTNode node) {
		var tmp = node
			while (!(tmp instanceof MethodDeclaration) && tmp !== null) {
				tmp = tmp.parent
		}
		tmp as MethodDeclaration
	}
	
	def static getFieldDeclaration(ASTNode node) {
		var tmp = node
			while (!(tmp instanceof FieldDeclaration) && tmp !== null) {
				tmp = tmp.parent
		}
		tmp as FieldDeclaration
	}
	
	def static getVariableDeclaration(ASTNode node) {
		var tmp = node
			while (!(tmp instanceof VariableDeclarationStatement) && tmp !== null) {
				tmp = tmp.parent
		}
		tmp as VariableDeclarationStatement
	}
	
	
}