package hu.elte.refjava.control.library;

import java.io.IOException;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;

import org.eclipse.core.runtime.FileLocator;
import org.eclipse.core.runtime.IPath;
import org.eclipse.core.runtime.Path;
import org.eclipse.core.runtime.Platform;
import org.eclipse.jdt.core.IAccessRule;
import org.eclipse.jdt.core.IClasspathContainer;
import org.eclipse.jdt.core.IClasspathEntry;
import org.eclipse.jdt.core.JavaCore;
import org.osgi.framework.Bundle;

public class RuntimeLibraryContainer implements IClasspathContainer {

	private static final String BIN_FOLDER_IN_PLUGIN = "bin";
	private static final String SRC_FOLDER_IN_PLUGIN = "src";

	public static final String[] BUNDLE_IDS_TO_INCLUDE = { "org.eclipse.text", "org.eclipse.jdt.core",
			"org.eclipse.jface.text", "hu.elte.refjava" };

	private final IPath containerPath;
	private IClasspathEntry[] classPathEntries;

	public RuntimeLibraryContainer(IPath containerPath) {
		this.containerPath = containerPath;
	}

	@Override
	public IClasspathEntry[] getClasspathEntries() {
		if (classPathEntries == null) {
			List<IClasspathEntry> cpEntries = new ArrayList<IClasspathEntry>();
			for (String bundleId : BUNDLE_IDS_TO_INCLUDE) {
				addEntry(cpEntries, bundleId);
			}
			classPathEntries = cpEntries.toArray(new IClasspathEntry[] {});
		}
		return classPathEntries;
	}

	private void addEntry(final List<IClasspathEntry> cpEntries, final String bundleId) {
		Bundle bundle = Platform.getBundle(bundleId);
		if (bundle != null) {
			cpEntries.add(JavaCore.newLibraryEntry(bundlePath(bundle), sourcePath(bundle), null, new IAccessRule[] {},
					null, false));
		}
	}

	private IPath bundlePath(Bundle bundle) {
		IPath path = binFolderPath(bundle);
		if (path == null) {
			// common jar file case, no bin folder
			try {
				path = new Path(FileLocator.getBundleFile(bundle).getAbsolutePath());
			} catch (IOException e) {
			}
		}
		return path;
	}

	private IPath binFolderPath(Bundle bundle) {
		URL binFolderURL = FileLocator.find(bundle, new Path(BIN_FOLDER_IN_PLUGIN), null);
		if (binFolderURL != null) {
			try {
				URL binFolderFileURL = FileLocator.toFileURL(binFolderURL);
				return new Path(binFolderFileURL.getPath()).makeAbsolute();
			} catch (IOException e) {
			}
		}
		return null;
	}

	private IPath sourcePath(Bundle bundle) {
		IPath path = srcFolderPath(bundle);
		if (path == null) {
			// common jar file case, no bin folder
			try {
				path = new Path(FileLocator.getBundleFile(bundle).getAbsolutePath());
			} catch (IOException e) {
			}
		}
		return path;
	}

	private IPath srcFolderPath(Bundle bundle) {
		URL binFolderURL = FileLocator.find(bundle, new Path(SRC_FOLDER_IN_PLUGIN), null);
		if (binFolderURL != null) {
			try {
				URL binFolderFileURL = FileLocator.toFileURL(binFolderURL);
				return new Path(binFolderFileURL.getPath()).makeAbsolute();
			} catch (IOException e) {
			}
		}
		return null;
	}

	@Override
	public String getDescription() {
		return "RefJava Runtime Library";
	}

	@Override
	public int getKind() {
		return IClasspathContainer.K_APPLICATION;
	}

	@Override
	public IPath getPath() {
		return containerPath;
	}

}
