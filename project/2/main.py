from collections import deque

from parser.ast import Node
from parser.parser import parser
from scanner.scanner import lexer
from parser.table import SymbolTable, SymbolScope, SymbolType, Symbol
from log import logger


def main():
    s = open('test.c').read()
    result = parser.parse(s)

    node_stack = [result]
    table_stack = [SymbolTable(SymbolScope.GLOBAL)]

    while node_stack:
        node = node_stack.pop()
        logger.debug(node)

        if node.symbol == 'function_def':
            msg = table_stack[0].set(node.args[1].symbol, Symbol(
                SymbolScope.GLOBAL,
                SymbolType.FUNCTION,
                {
                    'init': True,
                    'type': node.args[0],
                    'name': node.args[1],
                    'arg_type': node.args[2],
                    'arg': node.args[3],
                }
            ))
            if msg:
                logger.error(msg)
                continue

            table_stack.append(SymbolTable(SymbolScope.LOCAL))
            table_stack[-1].set(node.args[3].symbol, Symbol(
                SymbolScope.GLOBAL,
                SymbolType.VARIABLE,
                {
                    'value': None,
                    'type': node.args[2],
                    'name': node.args[3]
                }
            ))
            node_stack.append(Node('function_def_end'))
            node_stack.append(node.args[4])
        elif node.symbol == 'function_def_end':
            table_stack.pop()
        elif node.symbol == 'function_decl':
            msg = table_stack[0].set(node.args[1].symbol, Symbol(
                SymbolScope.GLOBAL,
                SymbolType.FUNCTION,
                {
                    'init': False,
                    'type': node.args[0],
                    'name': node.args[1],
                    'arg_type': node.args[2],
                    'arg': None
                }
            ))
            if msg:
                logger.error(msg)
        elif node.symbol == 'decl':
            for var in node.args[1:]:
                msg = table_stack[-1].set(var.symbol, Symbol(
                    SymbolScope.GLOBAL,
                    SymbolType.VARIABLE,
                    {
                        'value': None,
                        'type': node.args[0],
                        'name': var
                    }
                ))
                if msg:
                    logger.error(msg)
        else:
            if node.attrs.get('type') == 'identifier':
                if table_stack[-1].get(node.symbol) is None:
                    logger.error(f'{node.symbol} referenced before declaration')
            else:
                for child in reversed(node.args):
                    node_stack.append(child)


if __name__ == '__main__':
    main()
