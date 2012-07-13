import javax.xml.xpath.*
import javax.xml.parsers.DocumentBuilderFactory

def tattletaleTests(Map params = [:], directory) {
   directory = directory as File;
   def identifier = params["identifier"];
   if (identifier == null) identifier = directory.name;

   def dupsExceptions = params["dupsExceptions"];
   try {
	  def tttRep = new File(outputDir, "tattletale-${identifier}");
	  tattletaleGenReports(directory, tttRep);
	  tattletaleCheckReport(tttRep, dupsExceptions: dupsExceptions);
   } catch (Throwable t) {
	  def tttErr = new File(outputDir, "tattletale-${identifier}.err");
	  ps = new PrintStream(tttErr);
	  t.printStackTrace(ps);
	  errors.add("tattletale: ${identifier} test failed, see " + tttErr.getPath());
	  ps.close();
   } finally {
	  // clean-up
   }
}

@GrabResolver(name = 'jboss.dev.group', root = 'https://repository.jboss.org/nexus/content/groups/developer')
@Grab(group='org.jboss.tattletale', module='tattletale', version='1.1.2.Final')
def tattletaleGenReports(sourceDir, reportDir) {
  org.jboss.tattletale.Main.main((String[]) ["${sourceDir}","${reportDir}"]);
}

def tattletaleCheckReport(Map params = [:], reportDir) {
   tattletaleCheckDups(new File(reportDir, "multiplelocations/index.html"), params["dupsExceptions"]);
   tattletaleCheckMultiVersions(new File(reportDir, "eliminatejars/index.html"));
   // tattletaleListClasses(new File(reportDir, "classlocation/index.html"), new File(reportDir,"classes-list.txt"));
}

def tattletaleCheckDups(reportFile, exceptions = null) {
   def reportText = reportFile.text;

   // make sure no jars are listed
   if (reportText.contains(".jar")) {
	  if (exceptions == null || 0 == exceptions.size()) {
		 errors.add("tattletale: duplicate jar files to eliminate, see ${reportFile}");
		 return;
	  }

	  // we have positives, lets check for the exceptions
	  def tdPattern = ~"<td>.*?</td>";
	  def tds = reportText =~ tdPattern;
	  def bad = [];
	  def sanity = false;

	  while (tds.find()) {
		 def tdContent = tds.group().substring(4, tds.group().length() - 5);
		 // task.log(tdContent);
		 // split on any html tag
		 def textContent = tdContent.split("<(\\w*?)\\s.*?(?:</\\1>|/>)|<br>");
		 // task.log("${textContent}");

		 // ignore record if content not text (i.e. jar link cell)
		 if (textContent.size() == 0) continue;
		 // we should not have a field with one jar because we are talking about duplicates
		 assert textContent.size() > 1;
		 // make sure all reported files are jars
		 assert textContent.every { it.endsWith(".jar") }
		 // we got further enough to think we parsed the page correctly
		 sanity = true;

		 def matches = 0;
		 exceptions.each { exception ->
			textContent.each { jar ->
			   if (jar =~ exception) matches++;
			}
		 }
		 if (textContent.size() - matches == 1) continue;
		 if (textContent.size() - matches > 1) errors.add("tattletale: duplicate ${new File(textContent[0]).name}, see ${reportFile}");
		 // check we don't match more than sane
		 assert (textContent.size() - matches > 0);
	  }

	  // confirm we found some jars
	  assert sanity;
   }
}

def tattletaleCheckMultiVersions(reportFile) {
   // make sure no jars are listed
   if (reportFile.text.contains(".jar"))
	  errors.add("tattletale: multiple versions of same jar, see ${reportFile}");
}

def processXml(String xml, String xpathQuery) {
	def factory = XPathFactory.newInstance();
	factory.setValidating();
	def xpath = factory.newXPath();
	def builder = DocumentBuilderFactory.newInstance().newDocumentBuilder();
	def inputStream = new ByteArrayInputStream(xml.bytes);
	def records = builder.parse(inputStream).documentElement;
	xpath.evaluate(xpathQuery, records);
  }
  

def tattletaleListClasses(file, destFile) {
   def textToProcess = file.text;
   def processedXPath = processXml(textToProcess, "//table/tbody/tr/td[1]")
   def list = eList.collect { processedXPath }
   destFile.write(list.join("\n"));
}

def getArgProperty(propName) {
	return System.getProperty(propName) ?: System.getenv(propName)
}

def tc5DupsExcludes = [
   "server/lib/.*?catalina-ant.*?\\.jar\$",
   "server/webapps/admin/WEB-INF/lib/.*?commons-beanutils.*?\\.jar\$",
   "server/webapps/admin/WEB-INF/lib/.*?commons-collections.*?\\.jar\$",
   "server/webapps/admin/WEB-INF/lib/.*?commons-digester.*?\\.jar\$",
   "server/lib/.*?commons-el.*?\\.jar\$",
   "server/webapps/manager/WEB-INF/lib/.*?commons-fileupload.*?\\.jar\$",
   "server/webapps/manager/WEB-INF/lib/.*?commons-io.*?\\.jar\$",
   "common/lib/.*?commons-logging-api.*?\\.jar\$",
   "common/lib/.*?mx4j.*?\\.jar\$",
   "server/lib/.*?mx4j.*?\\.jar\$"
]


/**
 * Execution of program
 */
errors = [];  // lets record non-blocking errors here
testDir = getArgProperty("testdir");
if (testDir.trim().equals("")) {
	throw new Exception("Property 'testdir' was not specified. Please define which directory should be the report created for by -Dtestdir=...");
}
outputDir = getArgProperty("output");  //setting global variable
if (outputDir.trim().equals("")) {
	println("Property 'output' was not defined. Using current directory './'");
	outputDir = "./";
}
dir = new File(testDir);
runIdentifier = dir.getName();
tattletaleTests(dir, identifier: runIdentifier);

// Check for errors before we finish
if (errors.size() > 0) {
   println(errors.size() + " errors detected:");
   errors.each() {
	  println(it);
   }
   throw new Exception("Errors were detected. See above!");
}
