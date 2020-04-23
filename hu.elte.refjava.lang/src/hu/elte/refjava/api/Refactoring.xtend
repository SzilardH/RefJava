package hu.elte.refjava.api

import hu.elte.refjava.lang.refJava.Visibility
import java.util.List
import java.util.Map
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.Expression
import org.eclipse.jdt.core.dom.SingleVariableDeclaration
import org.eclipse.jdt.core.dom.Type
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jface.text.IDocument

interface Refactoring {
	
	val Map<String, List<? extends ASTNode>> bindings = newHashMap
	val Map<String, String> nameBindings = newHashMap
	val Map<String, Type> typeBindings = newHashMap
	val Map<String, List<SingleVariableDeclaration>> parameterBindings = newHashMap
	val Map<String, Visibility> visibilityBindings = newHashMap
	val Map<String, List<Expression>> argumentBindings = newHashMap
	
	
	enum Status {
		SUCCESS,
		MATCH_FAILED,
		CHECK_FAILED,
		BUILD_FAILED,
		REPLACEMENT_FAILED,
		TARGET_MATCH_FAILED
	}
	
	def void init(List<? extends ASTNode> target, IDocument document, List<TypeDeclaration> allTypeDeclInWorkspace)

	def Status apply()

}
