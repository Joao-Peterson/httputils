program test;

{$APPTYPE CONSOLE}



{$R *.res}



{$R 'modules\dunitx\Source\DUNitX.Loggers.GUIX.fmx' :TForm(DUNitX.Loggers.GUIX)}

uses
  System.SysUtils,
  querystringU in '..\src\querystringU.pas',
  testsU in 'testsU.pas',
  httpUtilsU in '..\src\httpUtilsU.pas',
  DUnitX.Assert.Ex.pas in 'modules\dunitx\Source\DUnitX.Assert.Ex.pas',
  DUnitX.Assert.pas in 'modules\dunitx\Source\DUnitX.Assert.pas',
  DUnitX.Attributes.pas in 'modules\dunitx\Source\DUnitX.Attributes.pas',
  DUnitX.AutoDetect.Console.pas in 'modules\dunitx\Source\DUnitX.AutoDetect.Console.pas',
  DUnitX.Banner.pas in 'modules\dunitx\Source\DUnitX.Banner.pas',
  DUnitX.CategoryExpression.pas in 'modules\dunitx\Source\DUnitX.CategoryExpression.pas',
  DUnitX.CommandLine.OptionDef.pas in 'modules\dunitx\Source\DUnitX.CommandLine.OptionDef.pas',
  DUnitX.CommandLine.Options.pas in 'modules\dunitx\Source\DUnitX.CommandLine.Options.pas',
  DUnitX.CommandLine.Parser.pas in 'modules\dunitx\Source\DUnitX.CommandLine.Parser.pas',
  DUnitX.ComparableFormat.pas in 'modules\dunitx\Source\DUnitX.ComparableFormat.pas',
  DunitX.ConsoleWriter.Base.pas in 'modules\dunitx\Source\DunitX.ConsoleWriter.Base.pas',
  DUnitX.Constants.pas in 'modules\dunitx\Source\DUnitX.Constants.pas',
  DUnitX.DUnitCompatibility.pas in 'modules\dunitx\Source\DUnitX.DUnitCompatibility.pas',
  DUnitX.Exceptions.pas in 'modules\dunitx\Source\DUnitX.Exceptions.pas',
  DUnitX.Extensibility.pas in 'modules\dunitx\Source\DUnitX.Extensibility.pas',
  DUnitX.Extensibility.PluginManager.pas in 'modules\dunitx\Source\DUnitX.Extensibility.PluginManager.pas',
  DUnitX.FilterBuilder.pas in 'modules\dunitx\Source\DUnitX.FilterBuilder.pas',
  DUnitX.Filters.pas in 'modules\dunitx\Source\DUnitX.Filters.pas',
  DUnitX.FixtureProviderPlugin.pas in 'modules\dunitx\Source\DUnitX.FixtureProviderPlugin.pas',
  DUnitX.FixtureResult.pas in 'modules\dunitx\Source\DUnitX.FixtureResult.pas',
  DUnitX.Generics.pas in 'modules\dunitx\Source\DUnitX.Generics.pas',
  DUnitX.Helpers.pas in 'modules\dunitx\Source\DUnitX.Helpers.pas',
  DUnitX.InternalDataProvider.pas in 'modules\dunitx\Source\DUnitX.InternalDataProvider.pas',
  DUnitX.InternalInterfaces.pas in 'modules\dunitx\Source\DUnitX.InternalInterfaces.pas',
  DUnitX.IoC.pas in 'modules\dunitx\Source\DUnitX.IoC.pas',
  DUnitX.Loggers.Console.pas in 'modules\dunitx\Source\DUnitX.Loggers.Console.pas',
  DUnitX.Loggers.Null.pas in 'modules\dunitx\Source\DUnitX.Loggers.Null.pas',
  DUnitX.Loggers.Text.pas in 'modules\dunitx\Source\DUnitX.Loggers.Text.pas',
  DUnitX.Loggers.XML.NUnit.pas in 'modules\dunitx\Source\DUnitX.Loggers.XML.NUnit.pas',
  DUnitX.Loggers.XML.xUnit.pas in 'modules\dunitx\Source\DUnitX.Loggers.XML.xUnit.pas',
  DUnitX.MemoryLeakMonitor.Default.pas in 'modules\dunitx\Source\DUnitX.MemoryLeakMonitor.Default.pas',
  DUnitX.OptionsDefinition.pas in 'modules\dunitx\Source\DUnitX.OptionsDefinition.pas',
  DUnitX.ResStrs.pas in 'modules\dunitx\Source\DUnitX.ResStrs.pas',
  DUnitX.RunResults.pas in 'modules\dunitx\Source\DUnitX.RunResults.pas',
  DUnitX.StackTrace.EurekaLog7.pas in 'modules\dunitx\Source\DUnitX.StackTrace.EurekaLog7.pas',
  DUnitX.Test.pas in 'modules\dunitx\Source\DUnitX.Test.pas',
  DUnitX.TestDataProvider.pas in 'modules\dunitx\Source\DUnitX.TestDataProvider.pas',
  DUnitX.TestFixture.pas in 'modules\dunitx\Source\DUnitX.TestFixture.pas',
  DUnitX.TestFramework.pas in 'modules\dunitx\Source\DUnitX.TestFramework.pas',
  DUnitX.TestNameParser.pas in 'modules\dunitx\Source\DUnitX.TestNameParser.pas',
  DUnitX.TestResult.pas in 'modules\dunitx\Source\DUnitX.TestResult.pas',
  DUnitX.TestRunner.pas in 'modules\dunitx\Source\DUnitX.TestRunner.pas',
  DUnitX.Timeout.pas in 'modules\dunitx\Source\DUnitX.Timeout.pas',
  DUnitX.Types.pas in 'modules\dunitx\Source\DUnitX.Types.pas',
  DUnitX.Utils.pas in 'modules\dunitx\Source\DUnitX.Utils.pas',
  DUnitX.Utils.XML.pas in 'modules\dunitx\Source\DUnitX.Utils.XML.pas',
  DUnitX.WeakReference.pas in 'modules\dunitx\Source\DUnitX.WeakReference.pas',
  DUnitX.Windows.Console.pas in 'modules\dunitx\Source\DUnitX.Windows.Console.pas';

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
