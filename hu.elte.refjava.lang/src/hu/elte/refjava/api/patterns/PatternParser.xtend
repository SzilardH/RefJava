package hu.elte.refjava.api.patterns

import com.google.inject.Inject
import hu.elte.refjava.lang.refJava.File
import hu.elte.refjava.lang.refJava.SchemeInstanceRule
import java.io.ByteArrayInputStream
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.resource.XtextResource
import org.eclipse.xtext.resource.XtextResourceSet

class PatternParser {

	@Inject static XtextResourceSet resourceSet
	static Resource resource
	static boolean initialized = false

	def static parse(String patternString) {
		if (!initialized) {
			resourceSet.addLoadOption(XtextResource.OPTION_RESOLVE_ALL, Boolean.TRUE)
			resource = resourceSet.createResource(URI.createURI("dummy:/patterns.refjava"))
			initialized = true
		}

		if (resource.loaded) {
			resource.unload
		}

		val paddedPatternString = '''package p; local refactoring l() «patternString» ~ nothing'''
		val inputStream = new ByteArrayInputStream(paddedPatternString.bytes)
		resource.load(inputStream, resourceSet.loadOptions)

		val file = resource.contents.head as File
		val refact = file.refactorings.head as SchemeInstanceRule

		return refact.matchingPattern
	}

}
