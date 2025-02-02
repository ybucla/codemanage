# -*- coding: utf-8 -*-
import cmd
import string, sys

def main():
	# 创建CLI 实例并运行
	cli = CLI()
	cli.cmdloop()

class CLI(cmd.Cmd):
	def __init__(self):
		cmd.Cmd.__init__(self)
		self.prompt = '> ' # 定义命令行提示符

	def do_hello(self, arg): # 定义hello 命令所执行的操作
		print "hello again", arg, "!"

	def help_hello(self): # 定义hello 命令的帮助输出
		print "syntax: hello [message]",
		print "-- prints a hello message"

	def do_quit(self, arg): # 定义quit 命令所执行的操作
		sys.exit(1)

	def help_quit(self): # 定义quit 命令的帮助输出
		print "syntax: quit",
		print "-- terminates the application"

	# 定义quit 的快捷方式
	do_q = do_quit


if __name__ == '__main__':
	main()
