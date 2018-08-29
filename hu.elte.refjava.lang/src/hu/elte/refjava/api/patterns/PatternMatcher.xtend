package hu.elte.refjava.api.patterns

import hu.elte.refjava.lang.refJava.PBlockExpression
import hu.elte.refjava.lang.refJava.PExpression
import hu.elte.refjava.lang.refJava.PMetaVariable
import hu.elte.refjava.lang.refJava.Pattern
import java.util.List
import java.util.Map
import org.eclipse.jdt.core.dom.ASTNode
import org.eclipse.jdt.core.dom.Block

class PatternMatcher {

	val Pattern pattern
	Map<String, List<? extends ASTNode>> bindings = newHashMap

	new(Pattern pattern) {
		this.pattern = pattern
	}

	def getBindings() {
		bindings
	}

	def match(List<? extends ASTNode> target) {
		bindings.clear
		return doMatchChildren(pattern.patterns, target)
	}

	def private dispatch doMatch(PMetaVariable metaVar, ASTNode anyNode) {
		bindings.put(metaVar.name, #[anyNode])
		return true
	}

	def private dispatch boolean doMatch(PBlockExpression blockPattern, Block block) {
		doMatchChildren(blockPattern.expressions, block.statements)
	}

	def private dispatch doMatch(PExpression anyOtherPattern, ASTNode anyOtherNode) {
		false
	}

	def private doMatchChildren(List<PExpression> patterns, List<? extends ASTNode> nodes) {
		if (patterns.size == 1 && patterns.head instanceof PMetaVariable) {
			val metaVar = patterns.head as PMetaVariable
			if (metaVar.isMulti) {
				bindings.put(metaVar.name, nodes)
				return true
			}
		}

		if (patterns.size != nodes.size) {
			return false
		}

		val pIt = patterns.iterator
		val nIt = nodes.iterator
		while (pIt.hasNext) {
			if (!doMatch(pIt.next, nIt.next)) {
				return false
			}
		}

		return true
	}

}
