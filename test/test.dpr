program test;

{$APPTYPE CONSOLE}

{$R *.res}

{$R 'modules\dunitx\Source\DUNitX.Loggers.GUIX.fmx' :TForm(DUNitX.Loggers.GUIX)}

uses
  System.SysUtils,
  querystringU in '..\src\querystringU.pas',
  testsU in 'testsU.pas',
  httpUtilsU in '..\src\httpUtilsU.pas',
  DUnitX.Loggers.Null in 'modules\dunitx\Source\DUnitX.Loggers.Null.pas',
  DUnitX.Loggers.Text in 'modules\dunitx\Source\DUnitX.Loggers.Text.pas',
  DUnitX.Loggers.XML.NUnit in 'modules\dunitx\Source\DUnitX.Loggers.XML.NUnit.pas',
  DUnitX.Loggers.XML.xUnit in 'modules\dunitx\Source\DUnitX.Loggers.XML.xUnit.pas',
  DUnitX.MemoryLeakMonitor.Default in 'modules\dunitx\Source\DUnitX.MemoryLeakMonitor.Default.pas',
  DUnitX.OptionsDefinition in 'modules\dunitx\Source\DUnitX.OptionsDefinition.pas',
  DUnitX.ResStrs in 'modules\dunitx\Source\DUnitX.ResStrs.pas',
  DUnitX.RunResults in 'modules\dunitx\Source\DUnitX.RunResults.pas',
  DUnitX.StackTrace.EurekaLog7 in 'modules\dunitx\Source\DUnitX.StackTrace.EurekaLog7.pas',
  DUnitX.Test in 'modules\dunitx\Source\DUnitX.Test.pas',
  DUnitX.TestDataProvider in 'modules\dunitx\Source\DUnitX.TestDataProvider.pas',
  DUnitX.TestFixture in 'modules\dunitx\Source\DUnitX.TestFixture.pas',
  DUnitX.TestFramework in 'modules\dunitx\Source\DUnitX.TestFramework.pas',
  DUnitX.TestNameParser in 'modules\dunitx\Source\DUnitX.TestNameParser.pas',
  DUnitX.TestResult in 'modules\dunitx\Source\DUnitX.TestResult.pas',
  DUnitX.TestRunner in 'modules\dunitx\Source\DUnitX.TestRunner.pas',
  DUnitX.Timeout in 'modules\dunitx\Source\DUnitX.Timeout.pas',
  DUnitX.Types in 'modules\dunitx\Source\DUnitX.Types.pas',
  DUnitX.Utils in 'modules\dunitx\Source\DUnitX.Utils.pas',
  DUnitX.Utils.XML in 'modules\dunitx\Source\DUnitX.Utils.XML.pas',
  DUnitX.WeakReference in 'modules\dunitx\Source\DUnitX.WeakReference.pas',
  DUnitX.Windows.Console in 'modules\dunitx\Source\DUnitX.Windows.Console.pas',
  DUnitX.Assert.Ex in 'modules\dunitx\Source\DUnitX.Assert.Ex.pas',
  DUnitX.Assert in 'modules\dunitx\Source\DUnitX.Assert.pas',
  DUnitX.Attributes in 'modules\dunitx\Source\DUnitX.Attributes.pas',
  DUnitX.AutoDetect.Console in 'modules\dunitx\Source\DUnitX.AutoDetect.Console.pas',
  DUnitX.Banner in 'modules\dunitx\Source\DUnitX.Banner.pas',
  DUnitX.CategoryExpression in 'modules\dunitx\Source\DUnitX.CategoryExpression.pas',
  DUnitX.CommandLine.OptionDef in 'modules\dunitx\Source\DUnitX.CommandLine.OptionDef.pas',
  DUnitX.CommandLine.Options in 'modules\dunitx\Source\DUnitX.CommandLine.Options.pas',
  DUnitX.CommandLine.Parser in 'modules\dunitx\Source\DUnitX.CommandLine.Parser.pas',
  DUnitX.ComparableFormat.Csv in 'modules\dunitx\Source\DUnitX.ComparableFormat.Csv.pas',
  DUnitX.ComparableFormat in 'modules\dunitx\Source\DUnitX.ComparableFormat.pas',
  DUnitX.ComparableFormat.Xml in 'modules\dunitx\Source\DUnitX.ComparableFormat.Xml.pas',
  DUnitX.ConsoleWriter.Base in 'modules\dunitx\Source\DUnitX.ConsoleWriter.Base.pas',
  DUnitX.Constants in 'modules\dunitx\Source\DUnitX.Constants.pas',
  DUnitX.DUnitCompatibility in 'modules\dunitx\Source\DUnitX.DUnitCompatibility.pas',
  DUnitX.Exceptions in 'modules\dunitx\Source\DUnitX.Exceptions.pas',
  DUnitX.Extensibility in 'modules\dunitx\Source\DUnitX.Extensibility.pas',
  DUnitX.Extensibility.PluginManager in 'modules\dunitx\Source\DUnitX.Extensibility.PluginManager.pas',
  DUnitX.FilterBuilder in 'modules\dunitx\Source\DUnitX.FilterBuilder.pas',
  DUnitX.Filters in 'modules\dunitx\Source\DUnitX.Filters.pas',
  DUnitX.FixtureProviderPlugin in 'modules\dunitx\Source\DUnitX.FixtureProviderPlugin.pas',
  DUnitX.FixtureResult in 'modules\dunitx\Source\DUnitX.FixtureResult.pas',
  DUnitX.Generics in 'modules\dunitx\Source\DUnitX.Generics.pas',
  DUnitX.Helpers in 'modules\dunitx\Source\DUnitX.Helpers.pas',
  DUnitX.Init in 'modules\dunitx\Source\DUnitX.Init.pas',
  DUnitX.InternalDataProvider in 'modules\dunitx\Source\DUnitX.InternalDataProvider.pas',
  DUnitX.InternalInterfaces in 'modules\dunitx\Source\DUnitX.InternalInterfaces.pas',
  DUnitX.IoC in 'modules\dunitx\Source\DUnitX.IoC.pas',
  DUnitX.Linux.Console in 'modules\dunitx\Source\DUnitX.Linux.Console.pas',
  DUnitX.Loggers.Console in 'modules\dunitx\Source\DUnitX.Loggers.Console.pas',
  DUnitX.Loggers.GUI.VCL in 'modules\dunitx\Source\DUnitX.Loggers.GUI.VCL.pas' {GUIVCLTestRunner},
  DUnitX.Loggers.GUI.VCL.RichEdit in 'modules\dunitx\Source\DUnitX.Loggers.GUI.VCL.RichEdit.pas';

var
    runner : ITestRunner;
    results : IRunResults;
    logger : ITestLogger;
    nunitLogger : ITestLogger;
begin
    try
        //Create the runner
        runner := TDUnitX.CreateRunner;
        runner.UseRTTI := True;

        //tell the runner how we will log things

        if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
        begin
          logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
          runner.AddLogger(logger);
        end;

        nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
        runner.AddLogger(nunitLogger);

        //Run tests
        results := runner.Execute;

        System.Write('Done.. press <Enter> key to quit.');
        System.Readln;
    except
        on E: Exception do Writeln(E.ClassName, ': ', E.Message);
    end;
end.
