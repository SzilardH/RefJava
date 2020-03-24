package hu.elte.refjava.api.patterns

import org.eclipse.jdt.core.dom.PrimitiveType
import org.eclipse.jdt.core.dom.AST

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
			val simpleName = id.split("\\.")
			return ast.newSimpleType(ast.newSimpleName(simpleName.last))
		}
	}
	
}