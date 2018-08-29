package hu.elte.refjava.lang

import com.google.inject.Binder
import hu.elte.refjava.api.patterns.PatternParser
import hu.elte.refjava.lang.compiler.RefJavaCompiler
import hu.elte.refjava.lang.scoping.RefJavaImplicitlyImportedFeatures
import hu.elte.refjava.lang.typesystem.RefJavaTypeComputer
import org.eclipse.xtext.xbase.compiler.XbaseCompiler
import org.eclipse.xtext.xbase.scoping.batch.ImplicitlyImportedFeatures
import org.eclipse.xtext.xbase.typesystem.computation.ITypeComputer

class RefJavaRuntimeModule extends AbstractRefJavaRuntimeModule {

	override configure(Binder binder) {
		super.configure(binder);
		binder.requestStaticInjection(PatternParser)
	}

	def Class<? extends ITypeComputer> bindITypeComputer() {
		RefJavaTypeComputer
	}

	def Class<? extends XbaseCompiler> bindXbaseCompiler() {
		RefJavaCompiler
	}

	def Class<? extends ImplicitlyImportedFeatures> bindImplicitlyImportedFeatures() {
		return RefJavaImplicitlyImportedFeatures
	}

}
