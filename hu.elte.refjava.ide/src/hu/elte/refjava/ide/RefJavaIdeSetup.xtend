package hu.elte.refjava.ide

import com.google.inject.Guice
import hu.elte.refjava.RefJavaRuntimeModule
import hu.elte.refjava.RefJavaStandaloneSetup
import org.eclipse.xtext.util.Modules2

class RefJavaIdeSetup extends RefJavaStandaloneSetup {

	override createInjector() {
		Guice.createInjector(Modules2.mixin(new RefJavaRuntimeModule, new RefJavaIdeModule))
	}

}
