package hu.elte.refjava.lang

class RefJavaStandaloneSetup extends RefJavaStandaloneSetupGenerated {

	def static void doSetup() {
		new RefJavaStandaloneSetup().createInjectorAndDoEMFRegistration()
	}

}
