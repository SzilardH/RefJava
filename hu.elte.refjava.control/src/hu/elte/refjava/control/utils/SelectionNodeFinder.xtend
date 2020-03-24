package hu.elte.refjava.control.utils

import com.google.common.collect.Range
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.Block
import org.eclipse.jdt.core.dom.CompilationUnit
import org.eclipse.jdt.core.dom.NodeFinder
import org.eclipse.jdt.core.dom.TypeDeclaration
import org.eclipse.jface.text.ITextSelection

class SelectionNodeFinder {

	def static selectedNodes(ITextSelection selection, CompilationUnit compilationUnit) {
		val finder = new NodeFinder(compilationUnit, selection.offset, selection.length)
		val coveringNode = finder.coveringNode
		
		if (coveringNode == finder.coveredNode) {
			return #[coveringNode]
		}
		
		val selectionRange = Range.closed(selection.offset, selection.offset + selection.length)
		return coveringNode.children.filter [
			val nodeRange = Range.closed(startPosition, startPosition + length)
			return nodeRange.isConnected(selectionRange) && !nodeRange.intersection(selectionRange).empty
		].toList
	}

	def private static dispatch getChildren(TypeDeclaration it) {
		fields.toList + methods.toList
	}

	def private static dispatch getChildren(Block it) {
		statements.toList
	}

	def private static dispatch getChildren(ASTNode coveringNode) {
		#[coveringNode]
	}

}
