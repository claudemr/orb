/* ORB - 3D/physics/AI engine
   Copyright (C) 2015-2017 Claude

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program. If not, see <http://www.gnu.org/licenses/>. */

module orb.utils.logger;


public import std.experimental.logger;
import std.stdio;



/**
 * That logger should support more option
 */
class FileExtLogger : Logger
{
    import std.concurrency : Tid;
    import std.datetime : SysTime;
    import std.format : formattedWrite;

public:
    this(in string fn, const LogLevel lv = LogLevel.all) @safe
    {
        super(lv);
        this.mFilename = fn;
        this.mFile.open(this.mFilename, "a");
    }

    this(File file, const LogLevel lv = LogLevel.all) @safe
    {
        super(lv);
        this.mFile = file;
    }

    @property File file() @safe
    {
        return this.mFile;
    }

    string filename() @property
    {
        return this.mFilename;
    }

protected:
    override void beginLogMsg(string file, int line, string funcName,
        string prettyFuncName, string moduleName, LogLevel logLevel,
        Tid threadId, SysTime timestamp, Logger logger)
        @safe
    {
    }

    override void logMsgPart(const(char)[] msg)
    {
        formattedWrite(this.mFile.lockingTextWriter(), "%s", msg);
    }

    override void finishLogMsg()
    {
        this.mFile.lockingTextWriter().put("\n");
        this.mFile.flush();
    }

    override void writeLogMsg(ref LogEntry payload)
    {
        this.beginLogMsg(payload.file, payload.line, payload.funcName,
            payload.prettyFuncName, payload.moduleName, payload.logLevel,
            payload.threadId, payload.timestamp, payload.logger);
        this.logMsgPart(payload.msg);
        this.finishLogMsg();
    }

    File   mFile;
    string mFilename;
}
