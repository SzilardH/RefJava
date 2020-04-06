package hu.elte.refjava.control.utils

import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.jdt.core.dom.TypeDeclaration
import java.util.List
import org.eclipse.jdt.core.dom.CompilationUnit
import org.eclipse.jdt.core.JavaCore
import org.eclipse.jdt.core.dom.ASTParser
import org.eclipse.jdt.core.dom.AST

class TypeDeclarationGetter {
		def static getAllTypeDeclarationInWorkspace() {
		val workspace = ResourcesPlugin.workspace
		val root = workspace.root
		val projects = root.projects
		
		val List<TypeDeclaration> allTypeDeclInWorkSpace = newArrayList
		for (project : projects) {
			val javaProject = JavaCore.create(project)
			val packages = javaProject.getPackageFragments()
			for (package : packages) {
				val iCompUnits = package.compilationUnits
				val List<CompilationUnit> allCompUnit = newArrayList
				for (iCompUnit : iCompUnits) {
					val parser = ASTParser.newParser(AST.JLS12);
					parser.source = iCompUnit;
					val compUnit = parser.createAST(null) as CompilationUnit;
					allCompUnit.add(compUnit)
			 	}
		 	
			 	for (compUnit : allCompUnit) {
			 		allTypeDeclInWorkSpace.addAll(compUnit.types)
			 	}
			}
		}
		allTypeDeclInWorkSpace
	}
}