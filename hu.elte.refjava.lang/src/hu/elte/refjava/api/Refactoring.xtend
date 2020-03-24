package hu.elte.refjava.api

import java.util.List
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jface.text.IDocument
import org.eclipse.jdt.core.ICompilationUnit

interface Refactoring {

	enum Status {
		SUCCESS,
		MATCH_FAILED,
		CHECK_FAILED,
		BUILD_FAILED,
		REPLACEMENT_FAILED,
		TARGET_MATCH_FAILED
	}

	def void init(List<? extends ASTNode> target, IDocument document, ICompilationUnit iCompUnit) {}

	def Status apply()

}
