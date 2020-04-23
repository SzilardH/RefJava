/*
 * generated by Xtext
 */
package hu.elte.refjava.lang.ide

import com.google.inject.Guice
import hu.elte.refjava.lang.RefJavaRuntimeModule
import hu.elte.refjava.lang.RefJavaStandaloneSetup
import org.eclipse.xtext.util.Modules2

/**
 * Initialization support for running Xtext languages as language servers.
 */
class RefJavaIdeSetup extends RefJavaStandaloneSetup {

	override createInjector() {
		Guice.createInjector(Modules2.mixin(new RefJavaRuntimeModule, new RefJavaIdeModule))
	}
}
